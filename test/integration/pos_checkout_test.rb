require "test_helper"

class PosCheckoutTest < ActionDispatch::IntegrationTest
  setup do
    @cashier = User.create!(name: "HTTP Cashier", email: "http@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
    category = Category.create!(name: "HTTP Category")
    @product = Product.create!(name: "HTTP Product", category: category, price: 100, cost: 50, stock: 10, tax_rate: 0, active: true)
  end

  test "cashier can sign in and complete a sale through the POS" do
    post user_session_path, params: { user: { email: @cashier.email, password: "password123" } }
    assert_redirected_to pos_root_path
    get pos_root_path
    assert_response :success
    post pos_sales_path, params: {
      terminal_id: "A", payment_method: "cash",
      items: { "0" => { product_id: @product.id, quantity: "2" } }
    }, as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal true, body["success"]
    assert_equal 200, body["total"]
    assert_equal 8, @product.reload.stock
    get ticket_pos_sale_path(body["sale_id"]), as: :json
    assert_response :success
    assert_equal "base64", response.parsed_body["encoding"]
    assert response.parsed_body["payload"].present?
  end

  test "anonymous checkout cannot change stock" do
    assert_no_difference "Sale.count" do
      post pos_sales_path, params: {
        terminal_id: "A", items: { "0" => { product_id: @product.id, quantity: "2" } }
      }, as: :json
      assert_response :unauthorized
    end
    assert_equal 10, @product.reload.stock
  end
end