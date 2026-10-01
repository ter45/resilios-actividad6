class Customer < ApplicationRecord
  include Discard::Model

  has_many :credits, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error

  enum :document_type, {
    cc: 0,    # Cédula de Ciudadanía
    nit: 1,   # NIT (empresas)
    ce: 2,    # Cédula de Extranjería
    pa: 3,    # Pasaporte
    ti: 4     # Tarjeta de Identidad
  }

  SEARCH_SIMILARITY_THRESHOLD = 0.1

  validates :name, presence: true, length: { minimum: 2, maximum: 120 }
  validates :document_number,
            length: { maximum: 30 },
            uniqueness: { case_sensitive: false, allow_nil: true, allow_blank: true }
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :address, length: { maximum: 200 }, allow_blank: true
  validates :credit_limit, numericality: { greater_than_or_equal_to: 0 }
  validates :credit_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :document_type, presence: true

  before_validation :normalize_document
  before_validation :normalize_phone

  scope :ordered,        -> { order(:name) }
  scope :active,         -> { kept.where(active: true) }
  scope :with_credit,    -> { where("credit_limit > 0") }
  scope :with_debt,      -> { where("credit_balance > 0") }
  scope :paid_up,        -> { where(credit_balance: 0) }

  scope :search_by_name, ->(query) {
    return all if query.blank?
    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
      .or(where("similarity(name, ?) > ?", query, SEARCH_SIMILARITY_THRESHOLD))
      .order(Arel.sql("similarity(name, #{connection.quote(query)}) DESC"))
  }

  scope :search, ->(query) {
    return all if query.blank?
    q = sanitize_sql_like(query)
    where("name ILIKE :q OR document_number = :exact OR phone = :exact",
          q: "%#{q}%", exact: query.strip)
  }

  def to_s
    name
  end

  def display_document
    return "—" if document_number.blank?
    "#{document_type.upcase} #{document_number}"
  end

  def can_buy_on_credit?
    active? && credit_limit.positive? && !discarded?
  end

  def available_credit
    [credit_limit - credit_balance, 0].max
  end

  def credit_used_percent
    return 0 if credit_limit.zero?
    ((credit_balance / credit_limit) * 100).round(1)
  end

  def in_debt?
    credit_balance.positive?
  end

  private

  def normalize_document
    self.document_number = document_number.to_s.strip.presence
  end

  def normalize_phone
    self.phone = phone.to_s.strip.gsub(/\s+/, " ").presence
  end
end
