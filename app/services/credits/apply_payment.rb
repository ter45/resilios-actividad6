module Credits
  class ApplyPayment
    Result = Struct.new(:success?, :payment, :credit, :errors, keyword_init: true)

    def initialize(credit:, amount:, user:, terminal_id:, notes: nil, paid_at: Time.current)
      @credit       = credit
      @amount       = amount.to_d
      @user         = user
      @terminal_id  = terminal_id.to_s
      @notes        = notes
      @paid_at      = paid_at
    end

    def call
      validate_inputs!

      ActiveRecord::Base.transaction do
        payment = create_payment!
        update_credit!
        update_customer_balance!

        Result.new(success?: true, payment: payment, credit: @credit.reload, errors: [])
      end
    rescue Credits::ApplyPayment::Error => e
      Result.new(success?: false, payment: nil, credit: @credit, errors: [e.message])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, payment: nil, credit: @credit, errors: e.record.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("Credits::ApplyPayment failed: #{e.class} #{e.message}")
      Result.new(success?: false, payment: nil, credit: @credit, errors: ["Error inesperado: #{e.message}"])
    end

    private

    Error = Class.new(StandardError)

    def validate_inputs!
      raise Error, "Crédito no encontrado"        if @credit.blank?
      raise Error, "Falta el cajero"              if @user.blank?
      raise Error, "Falta la terminal"            if @terminal_id.blank?
      raise Error, "Terminal inválida"            unless %w[A B].include?(@terminal_id)
      raise Error, "Monto inválido"               if @amount <= 0
      raise Error, "El crédito ya está pagado"    if @credit.paid?
      raise Error, "Monto mayor al saldo pendiente (#{@credit.balance.to_i})" if @amount > @credit.balance
    end

    def create_payment!
      Payment.create!(
        credit:       @credit,
        customer:     @credit.customer,
        user:         @user,
        terminal_id:  @terminal_id,
        amount:       @amount,
        paid_at:      @paid_at,
        notes:        @notes
      )
    end

    def update_credit!
      @credit.with_lock do
        new_balance = @credit.balance - @amount
        attrs = { balance: new_balance }

        if new_balance.zero?
          attrs[:status]  = :paid
          attrs[:paid_at] = @paid_at
        end

        @credit.update!(attrs)
      end
    end

    def update_customer_balance!
      @credit.customer.with_lock do
        new_balance = [@credit.customer.credit_balance - @amount, 0].max
        @credit.customer.update!(credit_balance: new_balance)
      end
    end
  end
end
