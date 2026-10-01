require "test_helper"
require Rails.root.join("db/seeds/farm_catalog")

class FarmCatalogTest < ActiveSupport::TestCase
  test "seed creates farm catalog and preserves subsequent prices stocks and custom products" do
    category = Category.find_or_create_by!(code: "ABA") { |record| record.name = "Abarrotes" }
    old = Product.find_or_create_by!(sku: "ARR-DIA-500") { |p| p.assign_attributes(name: "Arroz Diana 500g", category: category, price: 100, stock: 3) }
    original_stock = old.stock
    custom = Product.create!(name: "Producto propio", sku: "CUSTOM", category: category, stock: 2, price: 200)
    Seeds::FarmCatalog.call
    assert_not old.reload.active?
    assert custom.reload.active?
    assert category.reload.active?
    assert_equal 26, Product.where(sku: Seeds::FarmCatalog::PRODUCTS.map(&:first)).count
    farm = Product.find_by!(sku: "GR-MAI-KG")
    assert farm.weight?
    assert_equal 100, farm.stock
    assert_equal 2200, farm.price
    assert_nil farm.barcode
    farm.update!(stock: 25, price: 3000, tax_rate: "0.19")
    assert_no_difference ["Product.count", "Category.count"] do
      Seeds::FarmCatalog.call
    end
    assert_equal 25, farm.reload.stock
    assert_equal 3000, farm.price
    assert_equal BigDecimal("0.19"), farm.tax_rate
    assert_equal original_stock, old.reload.stock
  end
  test "seed fills empty placeholders but does not restock sold out products" do
    Seeds::FarmCatalog.call
    placeholder = Product.find_by!(sku: "AV-INI-40")
    placeholder.update!(price: 0, cost: 0, stock: 0)
    sold_out = Product.find_by!(sku: "GR-MAI-KG")
    sold_out.update!(price: 5000, cost: 3500, stock: 0)
    Seeds::FarmCatalog.call
    assert_equal 95000, placeholder.reload.price
    assert_equal 20, placeholder.stock
    assert_equal 5000, sold_out.reload.price
    assert_equal 0, sold_out.stock
    assert_equal 3500, sold_out.cost
    Seeds::FarmCatalog::PRODUCTS.each do |sku, *rest|
      assert_operator Product.find_by!(sku: sku).price, :>, 0
    end
  end
end