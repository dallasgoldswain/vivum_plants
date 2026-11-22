# Units of a fulfilled line a buyer sent back (SE06, D196). The seller decides on the spot
# where they go: saleable (checked and fine), unavailable (damaged) or lost.
class OrderReturn < ApplicationRecord
  OUTCOMES = { "saleable" => "Back in stock", "unavailable" => "Damaged, kept unavailable", "lost" => "Lost" }.freeze

  belongs_to :order_line
  belongs_to :stock_location
  belongs_to :member, class_name: "User", optional: true

  normalizes :reason, with: ->(value) { value.squish.presence }

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :outcome, inclusion: { in: OUTCOMES.keys }
  validates :reason, presence: true, length: { maximum: 200 }

  def readonly? = persisted?
end
