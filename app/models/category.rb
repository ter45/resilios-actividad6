class Category < ApplicationRecord
  include Discard::Model

  validates :name, presence: true, length: { minimum: 2, maximum: 60 }, uniqueness: { case_sensitive: false }
  validates :code, length: { maximum: 10 }, uniqueness: { case_sensitive: false, allow_nil: true, allow_blank: true }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :normalize_code

  scope :ordered,  -> { order(:position, :name) }
  scope :active,   -> { kept.where(active: true) }
  scope :inactive, -> { kept.where(active: false) }

  def to_s
    name
  end

  def toggle_active!
    update!(active: !active)
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase.presence
  end
end
