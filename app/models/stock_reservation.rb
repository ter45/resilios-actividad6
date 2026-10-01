class StockReservation < ApplicationRecord
  belongs_to :product
  belongs_to :user

  validates :cart_id,     presence: true
  validates :terminal_id, presence: true, inclusion: { in: %w[A B] }
  validates :quantity,    numericality: { greater_than: 0 }
  validates :expires_at,  presence: true

  scope :active,       -> { where("expires_at > ?", Time.current) }
  scope :expired,      -> { where("expires_at <= ?", Time.current) }
  scope :for_cart,     ->(cart_id) { where(cart_id: cart_id) }
  scope :for_product,  ->(product) { where(product: product) }

  def self.reserved_quantity_for(product)
    active.for_product(product).sum(:quantity)
  end

  def self.available_stock_for(product)
    [product.stock - reserved_quantity_for(product), 0].max
  end
end
