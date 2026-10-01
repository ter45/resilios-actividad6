module Stock
  class ReleaseExpired
    def self.call
      count = StockReservation.expired.delete_all
      Rails.logger.info("[Stock::ReleaseExpired] Liberadas #{count} reservaciones vencidas") if count.positive?
      count
    end
  end
end
