module Pos
  class ProductsController < ApplicationController
    before_action :authenticate_user!

    def search
      result = Catalog::Navigation.new(query: params[:q], category_id: params[:category_id], page: params[:page]).call
      reserved = StockReservation.active.where(product_id: result.products.map(&:id)).group(:product_id).sum(:quantity)
      render json: {
        products: result.products.map { |p| serialize(p, available_stock: [p.stock - reserved.fetch(p.id, 0), 0].max) },
        page: result.page, has_more: result.has_more, strategy: result.strategy
      }
    end

    def lookup_barcode
      barcode = params[:barcode].to_s.strip
      product = Product.sellable.find_by(barcode: barcode)

      if product
        render json: serialize(product)
      else
        render json: { error: "Producto no encontrado" }, status: :not_found
      end
    end

    private

    def serialize(p, available_stock: StockReservation.available_stock_for(p))
      {
        id:               p.id,
        name:             p.name,
        sku:              p.sku,
        barcode:          p.barcode,
        price:            p.price.to_f,
        tax_rate:         p.tax_rate.to_f,
        pricing_mode:     p.pricing_mode,
        category_name:    p.category.name,
        stock:            p.stock.to_f,
        available_stock:  available_stock.to_f,
        display_price:    p.display_price
      }
    end
  end
end
