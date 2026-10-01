module Pos
  class SalesController < ApplicationController
    require "base64"

    layout "pos"

    before_action :authenticate_user!
    before_action :ensure_can_sell
    before_action :set_sale, only: [:ticket, :receipt]
    before_action :set_suspended_sale, only: [:resume, :discard_suspended]

    def new
      @cart_id     = SecureRandom.uuid
      @terminal_id = current_user.terminal_assigned.presence || "A"
      @categories  = Category.kept.active.ordered
      @suspended_count = Sale.suspended_recent.by_terminal(current_user.terminal_assigned || "A").count
      @resume_payload = session.delete(:resume_payload)
    end

    def create
      service = Sales::Create.new(
        cashier:        current_user,
        terminal_id:    params[:terminal_id],
        cart_id:        params[:cart_id],
        customer:       find_customer(params[:customer_id]),
        payment_method: params[:payment_method] || :cash,
        cash_amount:    params[:cash_amount],
        credit_amount:  params[:credit_amount],
        items:          parse_items(params[:items])
      )
      result = service.call
      if result.success?
        render json: {
          success:    true,
          sale_id:    result.sale.id,
          sale_number: result.sale.number,
          total:      result.sale.total.to_i,
          subtotal:   result.sale.subtotal.to_i,
          tax_total:  result.sale.tax_total.to_i
        }
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    def suspend
      result = Sales::Suspend.new(
        cashier:        current_user,
        terminal_id:    params[:terminal_id],
        cart_id:        params[:cart_id],
        customer:       find_customer(params[:customer_id]),
        payment_method: params[:payment_method] || :cash,
        items:          parse_items(params[:items]),
        notes:          params[:notes]
      ).call

      if result.success?
        render json: {
          success:     true,
          sale_id:     result.sale.id,
          display:     result.sale.display_number,
          total:       result.sale.total.to_i,
          items_count: result.sale.sale_items.size
        }
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    def suspended_index
      @suspended = Sale.suspended_recent
                       .by_terminal(current_user.terminal_assigned || "A")
                       .includes(:user, :customer, :sale_items)
    end

    def resume
      cart_id = SecureRandom.uuid

      result = Sales::Resume.new(
        sale:    @suspended_sale,
        cashier: current_user,
        cart_id: cart_id
      ).call

      if result.success?
        session[:resume_payload] = {
          cart_id:    cart_id,
          items:      result.items_data,
          customer_id: @suspended_sale.customer_id,
          warnings:   result.warnings
        }
        redirect_to new_pos_sale_path
      else
        redirect_to suspended_pos_sales_path, alert: result.errors.join(", ")
      end
    end

    def discard_suspended
      if @suspended_sale.suspended?
        @suspended_sale.destroy
        flash[:notice] = "Venta suspendida descartada"
      else
        flash[:alert] = "Esa venta ya no está suspendida"
      end
      redirect_to suspended_pos_sales_path
    end

    def ticket
      authorize @sale, :show?
      bytes = Tickets::Build.new(sale: @sale).call
      render json: {
        sale_id: @sale.id,
        sale_number: @sale.number,
        encoding: "base64",
        payload: Base64.strict_encode64(bytes)
      }
    end

    def receipt
      authorize @sale, :show?
      @setting = Setting.current
      @paper = %w[a4 58 80].include?(params[:paper]) ? params[:paper] : @setting.paper_width_mm.to_s
      @items = @sale.sale_items.ordered
      render "sales/receipt", layout: false
    end
    private

    def ensure_can_sell
      return if current_user.can_sell?
      redirect_to admin_root_path, alert: "Acceso solo para cajeros."
    end

    def set_sale
      @sale = policy_scope(Sale).find(params[:id])
    end

    def set_suspended_sale
      @suspended_sale = Sale.suspended.find_by(id: params[:id])
      unless @suspended_sale
        redirect_to suspended_pos_sales_path, alert: "Venta suspendida no encontrada"
      end
    end

    def find_customer(id)
      return nil if id.blank?
      Customer.kept.find_by(id: id)
    end

    def parse_items(items_param)
      return [] if items_param.blank?
      items_param.values.map do |i|
        {
          product_id: i[:product_id],
          quantity:   i[:quantity]
        }
      end
    end
  end
end
