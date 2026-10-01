class Setting < ApplicationRecord
  has_one_attached :logo
  validate :acceptable_logo
  validates :business_name,   presence: true, length: { maximum: 120 }
  validates :legal_name,      length: { maximum: 200 }, allow_blank: true
  validates :nit,             length: { maximum: 30 },  allow_blank: true
  validates :address,         length: { maximum: 200 }, allow_blank: true
  validates :phone,           length: { maximum: 50 },  allow_blank: true
  validates :city,            length: { maximum: 100 }, allow_blank: true
  validates :ticket_header,   length: { maximum: 200 }, allow_blank: true
  validates :ticket_footer,   length: { maximum: 200 }, allow_blank: true
  validates :paper_width_mm,  inclusion: { in: [58, 80] }

  def self.current
    first_or_create!(business_name: "Minimercado")
  end

  def chars_per_line
    paper_width_mm == 58 ? 32 : 48
  end
  private

  def acceptable_logo
    return unless logo.attached?

    unless %w[image/png image/jpeg image/webp].include?(logo.blob.content_type)
      errors.add(:logo, "debe ser una imagen PNG, JPG o WebP")
    end
    if logo.blob.byte_size > 2.megabytes
      errors.add(:logo, "debe pesar como máximo 2 MB")
    end
  end
end