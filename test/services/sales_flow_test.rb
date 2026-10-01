require "test_helper"

class SalesFlowTest < ActiveSupport::TestCase
  setup do
    @cashier = User.create!(name: "Test Cashier", email: "flow@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
    @category = Category.create!(name: "Test Category")
    @product = Product.create!(name: "Test Product", category: @category, price: 100, cost: 50, stock: 10, tax_rate: 0, active: true)
    @customer = Customer.create!(name: "Test Customer", credit_limit: 1000, active: true)
  end

  def sell(quantity: 2, **options)
    Sales::Create.new(cashier: @cashier, terminal_id: "A", items: [{ product_id: @product.id, quantity: quantity }], **options).call
  end

  test "cash sale decrements stock and records totals" do
    result = sell
    assert result.success?, result.errors.inspect
    assert_equal 200, result.sale.total
    assert_equal 200, result.sale.cash_amount
    assert_equal 8, @product.reload.stock
    assert_nil result.sale.credit
  end

  test "weight sale preserves fractional quantity and pricing mode" do
    @product.update!(pricing_mode: :weight)
    result = sell(quantity: "0.250")
    assert result.success?, result.errors.inspect
    assert_equal 25, result.sale.total
    assert_equal BigDecimal("9.75"), @product.reload.stock
    assert result.sale.sale_items.first.weight?
  end

  test "insufficient stock leaves no sale or credit" do
    assert_no_difference ["Sale.count", "Credit.count"] do
      result = sell(quantity: 11, customer: @customer, payment_method: :credit)
      assert_not result.success?
    end
    assert_equal 10, @product.reload.stock
    assert_equal 0, @customer.reload.credit_balance
  end

  test "credit sale and payments keep balances consistent" do
    result = sell(customer: @customer, payment_method: :credit)
    assert result.success?, result.errors.inspect
    credit = result.sale.credit
    assert_equal 200, @customer.reload.credit_balance
    payment = Credits::ApplyPayment.new(credit: credit, amount: 50, user: @cashier, terminal_id: "A").call
    assert payment.success?, payment.errors.inspect
    assert_equal 150, credit.reload.balance
    assert_equal 150, @customer.reload.credit_balance
    rejected = Credits::ApplyPayment.new(credit: credit, amount: 151, user: @cashier, terminal_id: "A").call
    assert_not rejected.success?
    assert_equal 1, credit.payments.count
    payment = Credits::ApplyPayment.new(credit: credit, amount: 150, user: @cashier, terminal_id: "A").call
    assert payment.success?, payment.errors.inspect
    assert credit.reload.paid?
    assert_equal 0, @customer.reload.credit_balance
  end

  test "credit limit rejection rolls back sale and stock" do
    @customer.update!(credit_limit: 100)
    assert_no_difference ["Sale.count", "Credit.count"] do
      result = sell(customer: @customer, payment_method: :credit)
      assert_not result.success?
    end
    assert_equal 10, @product.reload.stock
    assert_equal 0, @customer.reload.credit_balance
  end

  test "inactive customers cannot receive credit" do
    @customer.update!(active: false)
    result = sell(customer: @customer, payment_method: :credit)
    assert_not result.success?
    assert_equal 10, @product.reload.stock
  end

  test "mixed payment checks only the credit portion against available credit" do
    @customer.update!(credit_limit: 100)
    result = sell(customer: @customer, payment_method: :mixed, cash_amount: 100, credit_amount: 100)
    assert result.success?, result.errors.inspect
    assert_equal 100, @customer.reload.credit_balance
    assert_equal 100, result.sale.credit.amount
  end

  test "existing debt reduces available credit" do
    @customer.update!(credit_limit: 250, credit_balance: 100)
    result = sell(customer: @customer, payment_method: :credit)
    assert_not result.success?
    assert_equal 100, @customer.reload.credit_balance
    assert_equal 10, @product.reload.stock
  end

  test "suspending a weight sale preserves its pricing mode without changing stock" do
    @product.update!(pricing_mode: :weight)
    result = Sales::Suspend.new(cashier: @cashier, terminal_id: "A", items: [{ product_id: @product.id, quantity: "0.250" }]).call
    assert result.success?, result.errors.inspect
    assert result.sale.sale_items.first.weight?
    assert_equal 10, @product.reload.stock
  end
end
