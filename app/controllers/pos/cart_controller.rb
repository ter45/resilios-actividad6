module Pos
  class CartController < ApplicationController
    before_action :authenticate_user!

    def add
      product = Product.sellable.find_by(id: params[:product_id])
      return render(json: { error: "Producto no encontrado" }, status: :not_found) unless product

      result = Stock::Reserve.new(
        product:     product,
        user:        current_user,
        terminal_id: params[:terminal_id] || current_user.terminal_assigned || "A",
        cart_id:     params[:cart_id],
        quantity:    params[:quantity].to_d
      ).call

      if result.success?
        render json: {
          success: true,
          reservation_id: result.reservation.id,
          available_stock: StockReservation.available_stock_for(product).to_f
        }
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    def remove
      reservation = StockReservation.find_by(id: params[:id])
      reservation&.destroy

      product = reservation&.product
      render json: {
        success: true,
        available_stock: product ? StockReservation.available_stock_for(product).to_f : nil
      }
    end

    def clear
      StockReservation.for_cart(params[:cart_id]).destroy_all
      render json: { success: true }
    end
  end
end
