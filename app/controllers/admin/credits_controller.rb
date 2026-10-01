module Admin
  class CreditsController < ApplicationController
    layout "admin"

    before_action :set_credit, only: %i[show pay]

    def index
      @scope = policy_scope(Credit).includes(:customer, :sale)

      @scope = @scope.where(status: params[:status]) if params[:status].present?
      if params[:customer_id].present?
        @scope = @scope.for_customer(Customer.find_by(id: params[:customer_id]))
      end

      @credits = @scope.ordered.limit(200)
      @customers = Customer.kept.with_credit.ordered

      @totals = {
        open_count:    Credit.pending.count,
        open_balance:  Credit.pending.sum(:balance),
        paid_count:    Credit.where(status: :paid).count,
        total_payments_today: Payment.today.sum(:amount)
      }

      authorize Credit
    end

    def show
      authorize @credit
      @payments = @credit.payments.recent
    end

    def pay
      authorize @credit, :pay?

      result = Credits::ApplyPayment.new(
        credit:      @credit,
        amount:      params[:amount].to_d,
        user:        current_user,
        terminal_id: params[:terminal_id] || current_user.terminal_assigned || "A",
        notes:       params[:notes]
      ).call

      if result.success?
        msg = "Abono de $#{result.payment.amount.to_i} aplicado."
        msg += " Crédito liquidado." if result.credit.paid?
        redirect_to admin_credit_path(@credit), notice: msg
      else
        redirect_to admin_credit_path(@credit), alert: result.errors.join(", ")
      end
    end

    private

    def set_credit
      @credit = Credit.find(params[:id])
    end
  end
end
