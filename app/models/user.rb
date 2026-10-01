class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :trackable, :validatable

  enum :role, {
    admin: 0,
    cashier: 1,
    supervisor: 2,
    viewer: 3
  }, validate: true

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :terminal_assigned, inclusion: { in: %w[A B], allow_nil: true }

  before_validation { self.terminal_assigned = terminal_assigned.presence }
  validates :terminal_assigned, presence: true, if: :cashier?

  def active_for_authentication?
    super && active?
  end

  scope :active, -> { where(active: true) }

  def display_name
    name.presence || email.split("@").first
  end

  def can_sell?
    active? && (admin? || cashier? || supervisor?)
  end
end
