module Stock
  class Reserve
    Result = Struct.new(:success?, :reservation, :errors, keyword_init: true)

    DEFAULT_TTL = 180

    def initialize(product:, user:, terminal_id:, cart_id:, quantity:, ttl: DEFAULT_TTL)
      @product     = product
      @user        = user
      @terminal_id = terminal_id.to_s
      @cart_id     = cart_id
      @quantity    = quantity.to_d
      @ttl         = ttl
    end

    def call
      available = StockReservation.available_stock_for(@product)
      if available < @quantity
        return Result.new(
          success?: false,
          reservation: nil,
          errors: ["Stock disponible insuficiente para #{@product.name} (disponible: #{available})"]
        )
      end

      reservation = StockReservation.create!(
        product:     @product,
        user:        @user,
        terminal_id: @terminal_id,
        cart_id:     @cart_id,
        quantity:    @quantity,
        expires_at:  Time.current + @ttl.seconds
      )

      Result.new(success?: true, reservation: reservation, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, reservation: nil, errors: e.record.errors.full_messages)
    end
  end
end
