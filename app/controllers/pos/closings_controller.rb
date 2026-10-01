module Pos
  class ClosingsController < ApplicationController
    layout "pos"
    before_action :authenticate_user!

    def new
      @terminal_id = current_user.terminal_assigned.presence || "A"
      @opened_at   = compute_opened_at
      @stats       = compute_stats
    end

    def create
      result = Cash::Close.new(
        user:         current_user,
        terminal_id:  params[:terminal_id],
        counted_cash: params[:counted_cash].to_d,
        notes:        params[:notes]
      ).call

      if result.success?
        render json: {
          success:        true,
          closing_id:     result.closing.id,
          expected_cash:  result.closing.expected_cash.to_i,
          counted_cash:   result.closing.counted_cash.to_i,
          difference:     result.closing.difference.to_i,
          status:         (result.closing.balanced? ? "balanced" : (result.closing.shortage? ? "shortage" : "surplus"))
        }
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    private

    def compute_opened_at
      terminal_id = current_user.terminal_assigned.presence || "A"
      last = CashClosing.last_closing_for(terminal_id)
      last ? last.closed_at : Time.current.beginning_of_day
    end

    def compute_stats
      terminal_id = current_user.terminal_assigned.presence || "A"
      opened_at   = compute_opened_at
      now         = Time.current

      sales = Sale.where(
        terminal_id: terminal_id,
        sold_at: opened_at..now
      )

      completed = sales.completed
      voided    = sales.voided

      {
        expected_cash:  completed.sum(:cash_amount),
        credit_total:   completed.sum(:credit_amount),
        sales_count:    completed.count,
        voided_count:   voided.count,
        opened_at:      opened_at,
        now:            now
      }
    end
  end
end
