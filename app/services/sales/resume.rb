module Sales
  class Resume
    Result = Struct.new(:success?, :sale, :items_data, :warnings, :errors, keyword_init: true)

    RESERVATION_TTL = 180.seconds

    def initialize(sale:, cashier:, cart_id:)
      @sale     = sale
      @cashier  = cashier
      @cart_id  = cart_id.to_s
    end

    def call
      validate_inputs!

      ActiveRecord::Base.transaction do
        warnings = []
        items_data = []

        @sale.sale_items.includes(:product).each do |item|
          if item.product.discarded?
            warnings << "Producto eliminado: #{item.product_name}. Se omitirá."
            next
          end

          available = StockReservation.available_stock_for(item.product)

          if available < item.quantity
            warnings << "Stock insuficiente para #{item.product.name}: pediste #{item.quantity}, hay #{available}."
            qty = available
          else
            qty = item.quantity
          end

          next if qty <= 0

          if qty > 0
            StockReservation.create!(
              product:     item.product,
              user:        @cashier,
              cart_id:     @cart_id,
              terminal_id: @sale.terminal_id,
              quantity:    qty,
              expires_at:  RESERVATION_TTL.from_now
            )
          end

          items_data << {
            product_id:   item.product.id,
            product_name: item.product.name,
            quantity:     qty,
            unit_price:   item.unit_price,
            adjusted:     qty != item.quantity
          }
        end

        # sale era solo un placeholder, lo descartamos directamente
        @sale.destroy!

        Result.new(success?: true, sale: @sale, items_data: items_data, warnings: warnings, errors: [])
      end
    rescue Sales::Resume::Error => e
      Result.new(success?: false, sale: @sale, items_data: [], warnings: [], errors: [e.message])
    rescue StandardError => e
      Rails.logger.error("Sales::Resume failed: #{e.class} #{e.message}")
      Result.new(success?: false, sale: @sale, items_data: [], warnings: [], errors: ["Error inesperado: #{e.message}"])
    end

    private

    Error = Class.new(StandardError)

    def validate_inputs!
      raise Error, "Venta no encontrada"             if @sale.blank?
      raise Error, "Falta el cajero"                 if @cashier.blank?
      raise Error, "Falta el cart_id"                if @cart_id.blank?
      raise Error, "La venta no está suspendida"     unless @sale.suspended?
    end
  end
end
