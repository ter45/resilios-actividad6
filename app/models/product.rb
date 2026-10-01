class Product < ApplicationRecord
  include Discard::Model

  belongs_to :category

  enum :pricing_mode, {
    unit: 0,
    weight: 1
  }

  validates :name,         presence: true, length: { minimum: 2, maximum: 120 }
  validates :sku,          length: { maximum: 30 },
                           uniqueness: { case_sensitive: false, allow_nil: true, allow_blank: true }
  validates :barcode,      length: { maximum: 30 },
                           uniqueness: { case_sensitive: false, allow_nil: true, allow_blank: true }
  validates :cost,         numericality: { greater_than_or_equal_to: 0 }
  validates :price,        numericality: { greater_than_or_equal_to: 0 }
  validates :stock,        numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate,     numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validates :pricing_mode, presence: true

  before_validation :normalize_sku
  before_validation :normalize_barcode

  SEARCH_SIMILARITY_THRESHOLD = 0.1

  scope :ordered,       -> { order(:name) }
  scope :page_size_limited, ->(limit = 100) { limit(limit) }
  scope :sellable,      -> { kept.where(active: true) }
  scope :in_stock,      -> { where("stock > 0") }
  scope :low_stock,     ->(threshold = 5) { where("stock > 0 AND stock <= ?", threshold) }
  scope :out_of_stock,  -> { where(stock: 0) }
  scope :by_category,   ->(category) { where(category: category) }

  scope :search_by_name, ->(query) {
    return all if query.blank?
    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
      .or(where("similarity(name, ?) > ?", query, SEARCH_SIMILARITY_THRESHOLD))
      .order(Arel.sql("similarity(name, #{connection.quote(query)}) DESC"))
  }

  scope :search, ->(query) {
    return all if query.blank?
    q = sanitize_sql_like(query)
    where("name ILIKE :q OR sku = :exact OR barcode = :exact",
          q: "%#{q}%", exact: query.strip)
  }

  def to_s
    name
  end

  def margin
    return 0 if cost.zero?
    ((price - cost) / cost * 100).round(2)
  end

  def in_stock?
    stock.positive?
  end

  def weight_priced?
    weight?
  end

  def display_price
    formatted = price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse
    "$ #{formatted}"
  end

  private

  def normalize_sku
    self.sku = sku.to_s.strip.upcase.presence
  end

  def normalize_barcode
    self.barcode = barcode.to_s.strip.presence
  end
end
