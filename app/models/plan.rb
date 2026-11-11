# A seller subscription plan (SB01, D21, D65). Operators edit prices and limits in /madmin.
class Plan < ApplicationRecord
  # New sellers start in Pilot on Pro (D25).
  DEFAULT_KEY = "pro"

  has_many :sellers, dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :monthly_price_cents, :member_limit, :photo_limit, :ai_extractions_per_month,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  def self.default = find_by!(key: DEFAULT_KEY)

  # Entitlements (config/features.yml `entitlement:`) are boolean columns on plans.
  def entitled_to?(entitlement)
    has_attribute?(entitlement) && self[entitlement] == true
  end

  def monthly_price = monthly_price_cents / 100.0
end
