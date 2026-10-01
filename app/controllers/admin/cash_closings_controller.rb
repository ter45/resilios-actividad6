module Admin
  class CashClosingsController < ApplicationController
    layout "admin"

    before_action :set_closing, only: [:show]

    def index
      @scope = policy_scope(CashClosing).includes(:user)

      @scope = @scope.where("closed_at >= ?", parsed_date.beginning_of_day) if params[:date].present?
      @scope = @scope.where("closed_at <= ?", parsed_date.end_of_day)       if params[:date].present?
      @scope = @scope.by_terminal(params[:terminal_id])                     if params[:terminal_id].present?
      @scope = @scope.for_user(params[:user_id])                            if params[:user_id].present?

      if params[:status] == "shortage"
        @scope = @scope.with_shortage
      elsif params[:status] == "surplus"
        @scope = @scope.with_surplus
      elsif params[:status] == "balanced"
        @scope = @scope.balanced
      end

      @closings = @scope.recent.limit(200)
      @users    = User.where(role: %i[cashier admin supervisor]).order(:name)
      @date     = params[:date].present? ? parsed_date : Date.current
      @totals   = compute_totals(@scope)

      authorize CashClosing
    end

    def show
      authorize @closing
      @sales_in_period = Sale.where(
        terminal_id: @closing.terminal_id,
        sold_at: @closing.opened_at..@closing.closed_at
      ).completed.recent
    end

    private

    def set_closing
      @closing = CashClosing.find(params[:id])
    end

    def parsed_date
      Date.parse(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end

    def compute_totals(scope)
      {
        count:          scope.count,
        expected_total: scope.sum(:expected_cash),
        counted_total:  scope.sum(:counted_cash),
        difference:     scope.sum(:difference),
        shortage_count: scope.with_shortage.count,
        surplus_count:  scope.with_surplus.count
      }
    end
  end
end
