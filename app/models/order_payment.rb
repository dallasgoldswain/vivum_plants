# Money in or out on an order, recorded by hand (PY03 manual, D189, D194). Never edited:
# a mistake is voided with a reason, and voided entries stop counting.
class OrderPayment < ApplicationRecord
  KINDS = %w[ payment refund ].freeze
  METHODS = { "eft" => "EFT", "cash" => "Cash", "card_machine" => "Card machine", "other" => "Other" }.freeze

  belongs_to :order
  belongs_to :recorded_by, class_name: "User", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  has_one :credit_note, -> { where(kind: "credit_note") }, class_name: "OrderDocument", dependent: :restrict_with_error

  enum :kind, KINDS.index_by(&:itself), validate: true, default: "payment"

  normalizes :reference, :reason, :void_reason, with: ->(value) { value.squish.presence }

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :method, inclusion: { in: METHODS.keys }
  validates :paid_on, presence: true
  validate { errors.add(:paid_on, "can't be in the future") if paid_on&.future? }
  validates :reference, :reason, :void_reason, length: { maximum: 200 }
  validates :reason, presence: { message: "is needed for a refund" }, if: :refund?

  scope :counted, -> { where(voided_at: nil) }

  def voided? = voided_at.present?
  def signed_cents = refund? ? -amount_cents : amount_cents
end
