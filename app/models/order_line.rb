# One stock item on an order (D179): its quantity and the price agreed when it was added,
# kept even when the item's or listing's price changes later (AT21). A reserved line holds
# its stock through a stock hold.
class OrderLine < ApplicationRecord
  STATES = %w[ active cancelled ].freeze

  belongs_to :order, inverse_of: :lines
  belongs_to :stock_item
  belongs_to :listing, optional: true
  belongs_to :stock_hold, optional: true

  enum :state, STATES.index_by(&:itself), validate: true, default: "active"

  normalizes :description, :price_reason, :cancel_reason, with: ->(value) { value.squish.presence }

  validates :description, presence: true, length: { maximum: 160 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { equal_to: 1, message: "of a specimen is 1" }, if: -> { stock_item&.specimen? }
  validates :agreed_price_cents, :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_reason, :cancel_reason, length: { maximum: 200 }

  def total_cents = quantity * unit_price_cents
  def price_changed? = unit_price_cents != agreed_price_cents
  def held? = stock_hold&.current? || false
end
