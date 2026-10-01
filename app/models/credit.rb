class Credit < ApplicationRecord
  belongs_to :customer
  belongs_to :sale

  has_many :payments, dependent: :restrict_with_error

  enum :status, {
    open: 0,
    paid: 1
  }

  validates :amount,  numericality: { greater_than: 0 }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :status,  presence: true

  scope :ordered,     -> { order(created_at: :desc) }
  scope :pending,     -> { where(status: :open) }
  scope :for_customer, ->(c) { where(customer: c) }

  def self.total_pending_for(customer)
    for_customer(customer).pending.sum(:balance)
  end

  def total_paid
    amount - balance
  end

  def paid_percent
    return 0 if amount.zero?
    ((total_paid / amount) * 100).round(1)
  end

  def display_balance
    "$ #{balance.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse}"
  end

  def display_amount
    "$ #{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse}"
  end
end
