# One line of the stock ledger (SE02, D157): what changed, how many, where, why and by whom.
# Movements are never edited; a mistake is corrected with another movement. Stock::Ledger
# writes them together with the balances they change.
class StockMovement < ApplicationRecord
  KINDS = %w[ receipt move mark_unavailable mark_available loss adjustment hold release expire fulfil to_collection return ].freeze
  BUCKETS = %w[ saleable unavailable ].freeze

  belongs_to :seller
  belongs_to :stock_item
  belongs_to :stock_location
  belongs_to :to_location, class_name: "StockLocation", optional: true
  belongs_to :stock_hold, optional: true
  belongs_to :member, class_name: "User", optional: true

  enum :kind, KINDS.index_by(&:itself), validate: true
  enum :bucket, BUCKETS.index_by(&:itself), validate: true, prefix: true

  validates :quantity, numericality: { only_integer: true }
  validates :reason, length: { maximum: 200 }

  scope :newest_first, -> { order(occurred_at: :desc, id: :desc) }

  def readonly? = persisted?
end
