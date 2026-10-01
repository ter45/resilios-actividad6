class SaleItem < ApplicationRecord
  belongs_to :sale, inverse_of: :sale_items
  belongs_to :product

  enum :pricing_mode, {
    unit: 0,
    weight: 1
  }

  validates :product_name,   presence: true
  validates :quantity,       numericality: { greater_than: 0 }
  validates :unit_price,     numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate,       numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validates :line_subtotal,  numericality: { greater_than_or_equal_to: 0 }
  validates :line_tax,       numericality: { greater_than_or_equal_to: 0 }
  validates :line_total,     numericality: { greater_than_or_equal_to: 0 }

  before_validation :prepare_line

  scope :ordered, -> { order(:position) }

  def display_quantity
    if weight?
      "#{quantity} kg"
    else
      quantity.to_i.to_s
    end
  end

  def display_line_total
    "$ #{line_total.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse}"
  end

  private

  def prepare_line
    snapshot_product_attributes
    compute_amounts
  end

  def snapshot_product_attributes
    return unless product
    self.product_name = product.name        if product_name.blank?
    self.product_sku  = product.sku         if product_sku.blank?
    self.pricing_mode = product.pricing_mode if new_record? || pricing_mode.blank?
    self.unit_price   = product.price       if unit_price.blank? || unit_price.zero?
    self.tax_rate     = product.tax_rate    if tax_rate.blank? || tax_rate.zero?
  end

  def compute_amounts
    self.quantity      ||= 0
    self.unit_price    ||= 0
    self.tax_rate      ||= 0

    base = (quantity.to_d * unit_price.to_d).round(2)
    self.line_subtotal = base
    self.line_tax      = (base * tax_rate.to_d).round(2)
    self.line_total    = line_subtotal + line_tax
  end
end
