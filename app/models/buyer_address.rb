# A South African delivery address for a buyer (D175); one is the default.
class BuyerAddress < ApplicationRecord
  PROVINCES = [ "Eastern Cape", "Free State", "Gauteng", "KwaZulu-Natal", "Limpopo", "Mpumalanga", "North West", "Northern Cape", "Western Cape" ].freeze

  belongs_to :buyer

  normalizes :label, :recipient, :street, :suburb, :city, with: ->(value) { value.squish.presence }
  normalizes :postal_code, with: ->(value) { value.gsub(/\s/, "") }

  validates :recipient, :street, :city, presence: true, length: { maximum: 120 }
  validates :label, :suburb, length: { maximum: 120 }
  validates :province, inclusion: { in: PROVINCES }
  validates :postal_code, format: { with: /\A\d{4}\z/, message: "must be 4 digits" }

  after_save :sole_default, if: -> { saved_change_to_default? && default? }
  before_create -> { self.default = true unless buyer.addresses.exists? }

  def one_line = [ street, suburb, city, postal_code ].compact.join(", ")

  private
    def sole_default
      buyer.addresses.where.not(id: id).update_all(default: false)
    end
end
