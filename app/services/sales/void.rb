module Sales
  class Void
    Result = Struct.new(:success?, :sale, :errors, keyword_init: true)

    def initialize(sale:, voided_by:, reason:)
      @sale       = sale
      @voided_by  = voided_by
      @reason     = reason.to_s.strip
    end

    def call
      validate_inputs!

      ActiveRecord::Base.transaction do
        revert_credit_if_applicable!
        restore_stock!
        revert_customer_balance!

        @sale.update!(
          status:         :voided,
          voided_at:      Time.current,
          voided_reason:  @reason,
          voided_by:      @voided_by
        )

        Result.new(success?: true, sale: @sale, errors: [])
      end
    rescue Sales::Void::Error => e
      Result.new(success?: false, sale: @sale, errors: [e.message])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, sale: @sale, errors: e.record.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("Sales::Void failed: #{e.class} #{e.message}")
      Result.new(success?: false, sale: @sale, errors: ["Error inesperado: #{e.message}"])
    end

    private

    Error = Class.new(StandardError)

    def validate_inputs!
      raise Error, "Venta no encontrada" if @sale.blank?
      raise Error, "Falta el usuario que anula" if @voided_by.blank?
      raise Error, "Se requiere razón de anulación" if @reason.blank?
      raise Error, "La venta ya está anulada" if @sale.voided?
      raise Error, "Solo se pueden anular ventas completadas" unless @sale.completed?

      credit = @sale.credit
      if credit && credit.payments.any?
        raise Error, "No se puede anular: el crédito tiene abonos registrados. Anulá los abonos primero."
      end
    end

    def revert_credit_if_applicable!
      return unless @sale.credit
      @sale.credit.destroy!
    end

    def restore_stock!
      @sale.sale_items.includes(:product).each do |item|
        next if item.product.discarded?
        item.product.with_lock do
          item.product.update!(stock: item.product.stock + item.quantity)
        end
      end
    end

    def revert_customer_balance!
      return if @sale.customer.blank?
      return if @sale.credit_amount.zero?

      @sale.customer.with_lock do
        new_balance = [@sale.customer.credit_balance - @sale.credit_amount, 0].max
        @sale.customer.update!(credit_balance: new_balance)
      end
    end
  end
end
