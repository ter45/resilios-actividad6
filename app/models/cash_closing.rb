class CashClosing < ApplicationRecord
  belongs_to :user

  validates :terminal_id,   presence: true, inclusion: { in: %w[A B] }
  validates :opened_at,     presence: true
  validates :closed_at,     presence: true
  validates :expected_cash, numericality: { greater_than_or_equal_to: 0 }
  validates :counted_cash,  numericality: { greater_than_or_equal_to: 0 }
  validates :sales_count,   numericality: { greater_than_or_equal_to: 0 }
  validates :voided_count,  numericality: { greater_than_or_equal_to: 0 }

  validate :closed_after_opened

  before_save :compute_difference

  scope :recent,        -> { order(closed_at: :desc) }
  scope :today,         -> { where("closed_at >= ?", Time.current.beginning_of_day) }
  scope :for_user,      ->(u) { where(user: u) }
  scope :by_terminal,   ->(t) { where(terminal_id: t) }
  scope :with_shortage, -> { where("difference < 0") }
  scope :with_surplus,  -> { where("difference > 0") }
  scope :balanced,      -> { where(difference: 0) }

  def self.last_closing_for(terminal_id)
    by_terminal(terminal_id).order(closed_at: :desc).first
  end

  def shortage?
    difference.negative?
  end

  def surplus?
    difference.positive?
  end

  def balanced?
    difference.zero?
  end

  def display_difference
    sign = difference.positive? ? "+" : (difference.negative? ? "-" : "")
    "#{sign}$ #{difference.to_i.abs.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1.').reverse}"
  end

  def duration_minutes
    return 0 if opened_at.blank? || closed_at.blank?
    ((closed_at - opened_at) / 60).to_i
  end

  private

  def closed_after_opened
    return if opened_at.blank? || closed_at.blank?
    errors.add(:closed_at, "debe ser posterior a la apertura") if closed_at <= opened_at
  end

  def compute_difference
    self.difference = counted_cash.to_d - expected_cash.to_d
  end
end
