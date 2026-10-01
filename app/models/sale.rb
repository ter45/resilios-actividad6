class Sale < ApplicationRecord
  belongs_to :user
  belongs_to :customer, optional: true
  belongs_to :voided_by, class_name: "User", optional: true

  has_many :sale_items, -> { order(:position) }, dependent: :destroy, inverse_of: :sale
  has_one :credit, dependent: :restrict_with_error

  accepts_nested_attributes_for :sale_items, allow_destroy: true

  enum :payment_method, {
    cash: 0,
    credit: 1,
    mixed: 2
  }

  enum :status, {
    pending: 0,
    completed: 1,
    voided: 2,
    suspended: 3
  }

  validates :number,         presence: true, uniqueness: true
  validates :terminal_id,    presence: true, inclusion: { in: %w[A B] }
  validates :subtotal,       numericality: { greater_than_or_equal_to: 0 }
  validates :tax_total,      numericality: { greater_than_or_equal_to: 0 }
  validates :discount_total, numericality: { greater_than_or_equal_to: 0 }
  validates :total,          numericality: { greater_than_or_equal_to: 0 }
  validates :cash_amount,    numericality: { greater_than_or_equal_to: 0 }
  validates :credit_amount,  numericality: { greater_than_or_equal_to: 0 }
  validate :amounts_must_match_total, on: :create, unless: :suspended?
  validate :credit_requires_customer, unless: :suspended?
  validate :suspended_at_present_if_suspended

  scope :recent,             -> { order(sold_at: :desc, created_at: :desc) }
  scope :today,              -> { where("sold_at >= ?", Time.current.beginning_of_day) }
  scope :on_date,            ->(date) { where(sold_at: date.beginning_of_day..date.end_of_day) }
  scope :by_terminal,        ->(t) { where(terminal_id: t) }
  scope :for_user,           ->(u) { where(user: u) }
  scope :credit_sales,       -> { where(payment_method: [:credit, :mixed]) }
  scope :suspended_recent,   -> { suspended.where("suspended_at >= ?", 24.hours.ago).order(suspended_at: :desc) }
  scope :suspended_old,      -> { suspended.where("suspended_at < ?", 24.hours.ago) }

  def display_number
    return "Suspendida ##{id}" if suspended?
    number
  end

  def display_total
    "$ #{total.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse}"
  end

  def items_count
    sale_items.sum(:quantity)
  end

  def has_credit?
    credit? || mixed?
  end

  def voidable?
    completed?
  end

  def resumable?
    suspended?
  end

  def display_customer
    customer&.name || "Público general"
  end

  private

  def amounts_must_match_total
    expected = cash_amount.to_d + credit_amount.to_d
    return if expected == total.to_d
    errors.add(:base, "La suma de pagos (#{expected}) no coincide con el total (#{total})")
  end

  def credit_requires_customer
    return unless has_credit?
    errors.add(:customer, "es obligatorio para ventas a crédito") if customer.blank?
  end

  def suspended_at_present_if_suspended
    return unless suspended?
    errors.add(:suspended_at, "es obligatorio para ventas suspendidas") if suspended_at.blank?
  end
end
