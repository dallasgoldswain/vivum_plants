# Where and how a plant was acquired (PL02). Cost is optional and kept in its original
# currency; no market value is inferred. Shaped to cover several plants for purchase groups
# (B16), one plant per acquisition for now.
class Acquisition < ApplicationRecord
  CURRENCIES = %w[ ZAR USD EUR GBP AUD THB IDR MYR ].freeze

  belongs_to :user
  has_many :plants, dependent: :nullify

  normalizes :source, :order_reference, with: ->(value) { value.strip.presence }
  normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :cost_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :source, :order_reference, length: { maximum: 200 }

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
