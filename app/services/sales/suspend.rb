module Sales
  class Suspend
    Result = Struct.new(:success?, :sale, :errors, keyword_init: true)

    def initialize(cashier:, terminal_id:, items:, cart_id: nil, customer: nil,
                   payment_method: :cash, notes: nil)
      @cashier        = cashier
      @terminal_id    = terminal_id.to_s
      @items          = items
      @cart_id        = cart_id
      @customer       = customer
      @payment_method = payment_method.to_sym
      @notes          = notes.to_s.strip.presence
    end

    def call
      validate_inputs!

      ActiveRecord::Base.transaction do
        sale = build_sale
        attach_items!(sale)
        compute_totals!(sale)
        sale.save!

        release_reservations!

        Result.new(success?: true, sale: sale, errors: [])
      end
    rescue Sales::Suspend::Error => e
      Result.new(success?: false, sale: nil, errors: [e.message])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, sale: nil, errors: e.record.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("Sales::Suspend failed: #{e.class} #{e.message}")
      Result.new(success?: false, sale: nil, errors: ["Error inesperado: #{e.message}"])
    end

    private

    Error = Class.new(StandardError)

    def validate_inputs!
      raise Error, "Falta el cajero"        if @cashier.blank?
      raise Error, "Falta la terminal"      if @terminal_id.blank?
      raise Error, "Terminal inválida"      unless %w[A B].include?(@terminal_id)
      raise Error, "El carrito está vacío"  if @items.blank?
      raise Error, "Método de pago inválido" unless Sale.payment_methods.key?(@payment_method.to_s)
    end

    def build_sale
      Sale.new(
        number:           draft_number,
        terminal_id:      @terminal_id,
        user:             @cashier,
        customer:         @customer,
        payment_method:   @payment_method,
        status:           :suspended,
        suspended_at:     Time.current,
        suspended_notes:  @notes,
        sold_at:          nil
      )
    end

    def draft_number
      "DRAFT-#{Time.current.strftime('%Y%m%d%H%M%S%L')}-#{@terminal_id}"
    end

    def attach_items!(sale)
      @items.each_with_index do |item_attrs, index|
        product = find_product(item_attrs)
        quantity = item_attrs[:quantity].to_d
        raise Error, "Cantidad inválida para #{product.name}" if quantity <= 0

        unit_price = item_attrs[:unit_price].present? ? item_attrs[:unit_price].to_d : product.price

        sale.sale_items.build(
          product:    product,
          quantity:   quantity,
          unit_price: unit_price,
          position:   index + 1
        )
      end
    end

    def find_product(item_attrs)
      pid = item_attrs[:product_id]
      product = Product.kept.find_by(id: pid)
      raise Error, "Producto no encontrado (id=#{pid})" unless product
      product
    end

    def compute_totals!(sale)
      sale.sale_items.each(&:valid?)
      sale.subtotal      = sale.sale_items.sum { |i| i.line_subtotal.to_d }
      sale.tax_total     = sale.sale_items.sum { |i| i.line_tax.to_d }
      sale.total         = (sale.subtotal + sale.tax_total).round(2)
      sale.cash_amount   = 0
      sale.credit_amount = 0
      sale.discount_total = 0
    end

    def release_reservations!
      return if @cart_id.blank?
      StockReservation.for_cart(@cart_id).destroy_all
    end
  end
end
