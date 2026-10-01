require "test_helper"

class CatalogNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Catalog Cashier", email: "catalog@example.test", password: "password123", role: :cashier, terminal_assigned: "A", active: true)
    @category = Category.create!(name: "Granos")
    @other = Category.create!(name: "Otros")
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
  end

  def product(name, **attributes)
    Product.create!({ name: name, category: @category, price: 100, cost: 50, stock: 10, active: true }.merge(attributes))
  end

  def search(**params)
    get "/pos/products/search", params: params, as: :json
    assert_response :success
    response.parsed_body
  end

  test "search respects category and excludes inactive and discarded products" do
    expected = product("Maiz amarillo")
    product("Maiz otro", category: @other)
    product("Maiz inactivo", active: false)
    product("Maiz descartado", discarded_at: Time.current)
    body = search(q: "Maiz", category_id: @category.id)
    assert_equal [expected.id], body.fetch("products").map { |p| p["id"] }
    assert_empty search(q: "No existe").fetch("products")
  end

  test "pages cover 85 equal names without duplicates and preserve category" do
    expected = 85.times.map { product("Producto repetido").id }
    product("Producto repetido", category: @other)
    pages = (1..3).map { |page| search(q: "Producto", category_id: @category.id, page: page) }
    assert_equal expected, pages.flat_map { |p| p.fetch("products").map { |r| r["id"] } }
    assert_equal [40, 40, 5], pages.map { |p| p.fetch("products").size }
    assert_equal [true, true, false], pages.map { |p| p["has_more"] }
    assert_equal 1, search(page: -3)["page"]
  end

  test "exact code takes precedence and honors category" do
    exact = product("Otro nombre", sku: "ABC-42", barcode: "1234567890123")
    by_name = product("Producto ABC-42")
    assert_equal [exact.id], search(q: "abc-42")["products"].map { |p| p["id"] }
    assert_equal "code", search(q: "1234567890123")["strategy"]
    assert_empty search(q: "ABC-42", category_id: @other.id)["products"]
    assert_equal [by_name.id], search(q: "Producto ABC")["products"].map { |p| p["id"] }
  end

  test "SQL wildcard input is literal" do
    exact = product("Maiz 100%")
    product("Maiz 1000")
    assert_equal [exact.id], search(q: "100%")["products"].map { |p| p["id"] }
    assert_empty search(q: "' OR 1=1 --")["products"]
  end

  test "availability respects active reservations expiration and weight" do
    weighted = product("Maiz pesado", pricing_mode: :weight, stock: 2.5)
    StockReservation.create!(product: weighted, user: @user, cart_id: "one", terminal_id: "A", quantity: 1.25, expires_at: 1.hour.from_now)
    StockReservation.create!(product: weighted, user: @user, cart_id: "old", terminal_id: "A", quantity: 8, expires_at: 1.hour.ago)
    row = search(q: "Maiz")["products"].first
    assert_equal 1.25, row["available_stock"]
    assert_equal "weight", row["pricing_mode"]
    weighted.update!(stock: 0)
    assert_equal 0, search(q: "Maiz")["products"].first["available_stock"]
  end

  test "barcode lookup retains product contract and missing result" do
    exact = product("Codigo", barcode: "1234567890123")
    get "/pos/products/lookup_barcode", params: { barcode: exact.barcode }, as: :json
    assert_response :success
    assert_equal exact.id, response.parsed_body["id"]
    get "/pos/products/lookup_barcode", params: { barcode: "missing" }, as: :json
    assert_response :not_found
  end

  test "anonymous navigation requires authentication" do
    delete destroy_user_session_path
    get "/pos/products/search", as: :json
    assert_response :unauthorized
  end

  test "reservation query count is constant for a full page" do
    45.times { |i| product("Grano #{i}") }
    queries = []
    callback = ->(*args) { queries << args.last[:sql] if args.last[:sql].match?(/SELECT.*stock_reservations/i) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { search(q: "Grano") }
    assert_equal 1, queries.size
  end
end
