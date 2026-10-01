require "test_helper"

class PrintableReceiptTest < ActionDispatch::IntegrationTest
  setup do
    @cashier = User.create!(name: "Windows Cashier", email: "windows@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
    product = Product.create!(name: "Alimento", category: Category.create!(name: "Windows Category"), stock: 5, price: 1200, tax_rate: 0)
    @sale = Sales::Create.new(cashier: @cashier, terminal_id: "A", items: [{ product_id: product.id, quantity: 1 }]).call.sale
    post user_session_path, params: { user: { email: @cashier.email, password: "password123" } }
  end

  test "receipt supports A4 and both thermal widths" do
    %w[a4 58 80].each do |paper|
      get receipt_pos_sale_path(@sale), params: { paper: paper }
      assert_response :success
      assert_select "article", text: /Alimento/
      assert_select "button", text: "Imprimir"
      assert_select "a[href=?]", pos_root_path
      assert_includes response.body, @sale.number
    end
  end

  test "another cashier cannot print a sale through either route" do
    delete destroy_user_session_path
    other = User.create!(name: "Other Cashier", email: "other.windows@example.test", password: "password123", role: :cashier, terminal_assigned: "B")
    post user_session_path, params: { user: { email: other.email, password: "password123" } }
    get receipt_pos_sale_path(@sale)
    assert_response :not_found
    get receipt_admin_sale_path(@sale)
    assert_response :not_found
  end
end