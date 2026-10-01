module Admin
  class SalesController < ApplicationController
    layout "admin"

    before_action :set_sale, only: %i[show void ticket receipt]

    def index
      @scope = policy_scope(Sale).includes(:user, :customer)

      @scope = @scope.on_date(parsed_date)                       if params[:date].present?
      @scope = @scope.by_terminal(params[:terminal_id])          if params[:terminal_id].present?
      @scope = @scope.for_user(params[:user_id])                 if params[:user_id].present?
      @scope = @scope.where(payment_method: params[:payment_method]) if params[:payment_method].present?
      @scope = @scope.where(status: params[:status])             if params[:status].present?

      @sales = @scope.recent.limit(200)

      @users       = User.where(role: %i[cashier admin supervisor]).order(:name)
      @date        = params[:date].present? ? parsed_date : Date.current

      @totals = compute_totals(@scope)
      authorize Sale
    end

    def show
      authorize @sale
      @items = @sale.sale_items.ordered.includes(:product)
    end

def ticket
  authorize @sale, :show?
  bytes = Tickets::Build.new(sale: @sale).call
  send_data bytes,
    type: "application/octet-stream",
    disposition: "attachment",
    filename: "ticket-#{@sale.number}.escpos"
end

    def void
      authorize @sale, :void?

      result = Sales::Void.new(
        sale:       @sale,
        voided_by:  current_user,
        reason:     params[:reason]
      ).call

      if result.success?
        redirect_to admin_sale_path(@sale), notice: "Venta #{@sale.number} anulada."
      else
        redirect_to admin_sale_path(@sale), alert: result.errors.join(", ")
      end
    end

    def receipt
      authorize @sale, :show?
      @setting = Setting.current
      @paper = %w[a4 58 80].include?(params[:paper]) ? params[:paper] : @setting.paper_width_mm.to_s
      @items = @sale.sale_items.ordered
      render "sales/receipt", layout: false
    end
    private

    def set_sale
      @sale = policy_scope(Sale).find(params[:id])
    end

    def parsed_date
      Date.parse(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end

    def compute_totals(scope)
      completed = scope.completed
      {
        count:        completed.count,
        total:        completed.sum(:total),
        cash_total:   completed.sum(:cash_amount),
        credit_total: completed.sum(:credit_amount),
        voided:       scope.voided.count
      }
    end
  end
end
