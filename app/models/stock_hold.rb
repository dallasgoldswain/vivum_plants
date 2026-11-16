# Units held for someone until a set time (D159, D14): there's no default expiry. A hold
# counts against availability while it's active and unexpired; it ends once, as released,
# fulfilled or expired.
class StockHold < ApplicationRecord
  STATES = %w[ active released fulfilled expired ].freeze

  belongs_to :stock_item
  belongs_to :stock_location
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :buyer, optional: true
  belongs_to :buyer_alias, optional: true
  has_many :movements, class_name: "StockMovement", dependent: :restrict_with_error

  enum :state, STATES.index_by(&:itself), validate: true, default: "active"

  normalizes :held_for, with: ->(value) { value.squish.presence }
  validates :held_for, presence: true, length: { maximum: 120 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :expires_at, presence: true

  # Holding stock now: active and not yet past its expiry, even before the job marks it.
  scope :current, -> { where(state: "active").where("expires_at > ?", Time.current) }
  scope :due_to_expire, -> { where(state: "active").where(expires_at: ..Time.current) }

  def current? = active? && expires_at > Time.current

  # Who it's for (D172): the buyer, the alias (with its linked buyer), or older free text.
  def holder_name
    if buyer then buyer.name
    elsif buyer_alias then [ buyer_alias.label, (" · #{buyer_alias.buyer.name}" if buyer_alias.buyer) ].join
    else held_for
    end
  end
end
