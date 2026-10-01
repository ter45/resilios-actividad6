module Cash
  class Close
    Result = Struct.new(:success?, :closing, :errors, keyword_init: true)

    def initialize(user:, terminal_id:, counted_cash:, notes: nil, closed_at: Time.current)
      @user         = user
      @terminal_id  = terminal_id.to_s
      @counted_cash = counted_cash.to_d
      @notes        = notes
      @closed_at    = closed_at
    end

    def call
      validate_inputs!

      ActiveRecord::Base.transaction do
        opened_at = compute_opened_at

        sales_in_period = Sale.where(
          terminal_id: @terminal_id,
          sold_at: opened_at..@closed_at
        )

        completed = sales_in_period.completed
        voided    = sales_in_period.voided

        payments_in_period = Payment.where(
          terminal_id: @terminal_id,
          paid_at: opened_at..@closed_at
        )

        sales_cash     = completed.sum(:cash_amount)
        payments_total = payments_in_period.sum(:amount)
        expected       = sales_cash + payments_total

        closing = CashClosing.create!(
          user:           @user,
          terminal_id:    @terminal_id,
          opened_at:      opened_at,
          closed_at:      @closed_at,
          expected_cash:  expected,
          counted_cash:   @counted_cash,
          credit_total:   completed.sum(:credit_amount),
          payments_total: payments_total,
          sales_count:    completed.count,
          voided_count:   voided.count,
          notes:          @notes
        )

        Result.new(success?: true, closing: closing, errors: [])
      end
    rescue Cash::Close::Error => e
      Result.new(success?: false, closing: nil, errors: [e.message])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, closing: nil, errors: e.record.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("Cash::Close failed: #{e.class} #{e.message}")
      Result.new(success?: false, closing: nil, errors: ["Error inesperado: #{e.message}"])
    end

    private

    Error = Class.new(StandardError)

    def validate_inputs!
      raise Error, "Falta el usuario"             if @user.blank?
      raise Error, "Falta la terminal"            if @terminal_id.blank?
      raise Error, "Terminal invalida"            unless %w[A B].include?(@terminal_id)
      raise Error, "Monto contado invalido"       if @counted_cash.negative?
    end

    def compute_opened_at
      last = CashClosing.last_closing_for(@terminal_id)
      return last.closed_at if last
      @closed_at.beginning_of_day
    end
  end
end
