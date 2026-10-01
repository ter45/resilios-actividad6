class Payment < ApplicationRecord
  belongs_to :credit
  belongs_to :customer
  belongs_to :user

  validates :terminal_id, presence: true, inclusion: { in: %w[A B] }
  validates :amount,      numericality: { greater_than: 0 }
  validates :paid_at,     presence: true

  scope :recent,        -> { order(paid_at: :desc) }
  scope :today,         -> { where("paid_at >= ?", Time.current.beginning_of_day) }
  scope :on_date,       ->(date) { where(paid_at: date.beginning_of_day..date.end_of_day) }
  scope :by_terminal,   ->(t) { where(terminal_id: t) }
  scope :for_user,      ->(u) { where(user: u) }
  scope :for_customer,  ->(c) { where(customer: c) }

  def display_amount
    "$ #{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse}"
  end
end
