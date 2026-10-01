module Sales
  class Create
    Result = Struct.new(:success?, :sale, :errors, keyword_init: true)

    DEFAULT_PAYMENT_METHOD = :cash

    def initialize(cashier:, terminal_id:, items:, cart_id: nil, customer: nil,
                   payment_method: DEFAULT_PAYMENT_METHOD,
                   cash_amount: nil, credit_amount: nil, discount_total: 0)
      @cashier        = cashier
      @terminal_id    = terminal_id.to_s
      @items          = items
      @cart_id        = cart_id
      @customer       = customer
      @payment_method = payment_method.to_sym
      @cash_amount    = cash_amount
      @credit_amount  = credit_amount
      @discount_total = discount_total.to_d
    end

    def call
      validate_inputs!

      ActiveRecord::Base.transaction do
        sale = build_sale
        attach_items!(sale)
        compute_totals!(sale)
        resolve_payment_amounts!(sale)
        sale.save!

        decrement_stock!(sale)
        consume_reservations!
        update_customer_balance!(sale)
        create_credit_if_applicable!(sale)

        Result.new(success?: true, sale: sale, errors: [])
      end
    rescue Sales::Create::Error => e
      Result.new(success?: false, sale: nil, errors: [e.message])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, sale: nil, errors: e.record.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("Sales::Create failed: #{e.class} #{e.message}")
      Result.new(success?: false, sale: nil, errors: ["Error inesperado: #{e.message}"])
    end

    private

    Error = Class.new(StandardError)

    def validate_inputs!
      raise Error, "Falta el cajero"          if @cashier.blank?
      raise Error, "Falta la terminal"        if @terminal_id.blank?
      raise Error, "Terminal inválida"        unless %w[A B].include?(@terminal_id)
      raise Error, "El carrito está vacío"    if @items.blank?
      raise Error, "Método de pago inválido"  unless Sale.payment_methods.key?(@payment_method.to_s)

      if (@payment_method == :credit || @payment_method == :mixed) && @customer.blank?
        raise Error, "Se requiere cliente para venta a crédito"
      end
    end

    def build_sale
      Sale.new(
        number:         Sales::BuildNumber.call(terminal_id: @terminal_id),
        terminal_id:    @terminal_id,
        user:           @cashier,
        customer:       @customer,
        payment_method: @payment_method,
        status:         :completed,
        discount_total: @discount_total,
        sold_at:        Time.current
      )
    end

    def attach_items!(sale)
      @items.each_with_index do |item_attrs, index|
        product = find_product(item_attrs)
        quantity = item_attrs[:quantity].to_d

        raise Error, "Cantidad inválida para #{product.name}" if quantity <= 0
        raise Error, "Sin stock suficiente de #{product.name}" if product.stock < quantity

        unit_price = item_attrs[:unit_price].present? ? item_attrs[:unit_price].to_d : product.price

        sale.sale_items.build(
          product:      product,
          quantity:     quantity,
          unit_price:   unit_price,
          position:     index + 1
        )
      end
    end

    def find_product(item_attrs)
      pid = item_attrs[:product_id]
      product = Product.kept.find_by(id: pid)
      raise Error, "Producto no encontrado (id=#{pid})" unless product
      raise Error, "Producto inactivo: #{product.name}" unless product.active?
      product
    end

    def compute_totals!(sale)
      sale.sale_items.each(&:valid?)
      sale.subtotal  = sale.sale_items.sum { |i| i.line_subtotal.to_d }
      sale.tax_total = sale.sale_items.sum { |i| i.line_tax.to_d }
      sale.total     = (sale.subtotal + sale.tax_total - @discount_total).round(2)
      raise Error, "Total negativo" if sale.total.negative?
    end

    def resolve_payment_amounts!(sale)
      case @payment_method
      when :cash
        sale.cash_amount   = sale.total
        sale.credit_amount = 0
      when :credit
        sale.cash_amount   = 0
        sale.credit_amount = sale.total
      when :mixed
        cash   = @cash_amount.to_d
        credit = @credit_amount.to_d
        raise Error, "Pagos no coinciden con el total" if (cash + credit).round(2) != sale.total.round(2)
        sale.cash_amount   = cash
        sale.credit_amount = credit
      end
    end

    def decrement_stock!(sale)
      sale.sale_items.each do |item|
        item.product.with_lock do
          if item.product.stock < item.quantity
            raise Error, "Stock insuficiente de #{item.product.name}"
          end
          item.product.update!(stock: item.product.stock - item.quantity)
        end
      end
    end

    def consume_reservations!
      return if @cart_id.blank?
      StockReservation.for_cart(@cart_id).destroy_all
    end

    def update_customer_balance!(sale)
      return if sale.customer.blank?
      return if sale.credit_amount.zero?
      sale.customer.with_lock do
        unless sale.customer.can_buy_on_credit?
          raise Error, "El cliente no tiene credito habilitado"
        end
        if sale.credit_amount > sale.customer.available_credit
          raise Error, "El monto supera el cupo de credito disponible"
        end
        new_balance = sale.customer.credit_balance + sale.credit_amount
        sale.customer.update!(credit_balance: new_balance)
      end
    end

    def create_credit_if_applicable!(sale)
      return if sale.credit_amount.zero?
      return if sale.customer.blank?

      Credit.create!(
        customer: sale.customer,
        sale:     sale,
        amount:   sale.credit_amount,
        balance:  sale.credit_amount,
        status:   :open
      )
    end
  end
end
