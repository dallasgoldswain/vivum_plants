# Where and how a plant was acquired (PL02). Cost is optional and kept in its original
# currency; no market value is inferred. A tissue culture purchase is a purchase group: one
# acquisition holding a record per plantlet, with the arrival quantity kept (TC01, D127).
class Acquisition < ApplicationRecord
  CURRENCIES = %w[ ZAR USD EUR GBP AUD THB IDR MYR ].freeze
  CONTAINER_CONDITIONS = %w[ intact condensation cloudy leaking damaged dried_out ].freeze
  MAX_PLANTLETS = 50

  belongs_to :user
  has_many :plants, dependent: :nullify
  has_many :photos, dependent: :destroy
  belongs_to :cover_photo, class_name: "Photo", optional: true

  normalizes :source, :order_reference, :name, with: ->(value) { value.strip.presence }
  normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :cost_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :source, :order_reference, length: { maximum: 200 }
  validates :name, length: { maximum: 120 }
  validates :container_condition, inclusion: { in: CONTAINER_CONDITIONS }, allow_nil: true

  scope :purchase_groups, -> { where(tissue_culture: true) }

  # How many of the purchase's records are still in the active collection (D129).
  def remaining = plants.in_active_collection.count

  # The form takes "120.50"; stored as cents.
  def cost
    cost_cents && format("%.2f", cost_cents / 100.0)
  end

  def cost=(value)
    self.cost_cents = value.blank? ? nil : (BigDecimal(value.to_s.delete(" ,")) * 100).round
  rescue ArgumentError
    self.cost_cents = -1 # fails validation: not a number
  end
end
