module Pos
  class CreditsController < ApplicationController
    layout "pos"
    before_action :authenticate_user!
    before_action :set_credit, only: %i[show pay]

    def index
      @scope = Credit.includes(:customer, :sale)

      if params[:q].present?
        customers = Customer.search(params[:q])
        @scope = @scope.where(customer: customers)
      end

      @scope = @scope.where(status: params[:status]) if params[:status].present?
      @credits = @scope.pending.ordered.limit(50)
    end

    def show
      @payments = @credit.payments.recent
    end

    def pay
      result = Credits::ApplyPayment.new(
        credit:      @credit,
        amount:      params[:amount].to_d,
        user:        current_user,
        terminal_id: current_user.terminal_assigned || "A",
        notes:       params[:notes]
      ).call

      if result.success?
        render json: {
          success:        true,
          payment_id:     result.payment.id,
          new_balance:    result.credit.balance.to_i,
          paid_percent:   result.credit.paid_percent,
          status:         result.credit.status,
          fully_paid:     result.credit.paid?
        }
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    private

    def set_credit
      @credit = Credit.find(params[:id])
    end
  end
end
