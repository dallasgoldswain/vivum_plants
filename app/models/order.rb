# An order (SE05, D179–D188): one seller and one buyer, numbered O-0001 per seller. Its
# state (draft, reserved, fulfilled, cancelled) is separate from its payment state, which
# stays unpaid until payments arrive (B23). Lines keep the price agreed when they were added.
# Stock changes go through Stock::Ledger, so holds and availability follow the stock rules.
class Order < ApplicationRecord
  include Order::Reserving
  include Order::Payments
  include Order::Returns
  include Order::LiveSale
  include Order::Packing

  STATES = %w[ draft reserved fulfilled cancelled ].freeze
  OPEN_STATES = %w[ draft reserved ].freeze
  SOURCES = { "chat" => "Chat", "in_person" => "In person", "request" => "Request", "live_sale" => "Live sale", "other" => "Other" }.freeze
  MANUAL_SOURCES = SOURCES.except("live_sale").freeze
  DELIVERY_METHODS = { "pickup" => "Pickup", "shipping" => "Shipping" }.freeze
  ADDRESS_FIELDS = %w[ recipient street suburb city province postal_code ].freeze

  belongs_to :seller
  belongs_to :buyer
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :fulfilled_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :lines, -> { order(:id) }, class_name: "OrderLine", inverse_of: :order, dependent: :destroy

  enum :state, STATES.index_by(&:itself), validate: true, default: "draft"

  normalizes :discount_reason, :courier, :tracking_reference, :cancel_reason, with: ->(value) { value.squish.presence }
  normalizes :notes, with: ->(value) { value.strip.presence }

  validates :source, inclusion: { in: SOURCES.keys }
  validates :delivery_method, inclusion: { in: DELIVERY_METHODS.keys }
  validates :shipping_cents, :discount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :discount_reason, presence: { message: "is needed for a discount" }, if: -> { discount_cents.positive? }
  validates :discount_reason, :courier, :tracking_reference, :cancel_reason, length: { maximum: 200 }
  validates :notes, length: { maximum: 1000 }
  validates :shipping_address, presence: { message: "is needed for shipping; add one to the buyer first" }, if: :shipping?
  validate { errors.add(:buyer, "must belong to this business") if buyer && buyer.seller_id != seller_id }
  validate { errors.add(:buyer, "has been deleted") if buyer&.deleted? && (new_record? || buyer_id_changed?) }

  before_validation :assign_reference, on: :create
  before_validation -> { self.buyer_name = buyer.name if buyer && (new_record? || buyer_id_changed?) }
  before_validation -> { self.shipping_address = nil if pickup? }

  scope :open, -> { where(state: OPEN_STATES) }
  scope :newest_first, -> { order(number: :desc) }
  # Paid orders whose hold time has passed, and overpaid orders (D189, D190).
  scope :needing_review, -> {
    where(payment_state: "overpaid").or(where(state: "reserved", payment_state: %w[ part_paid paid ]).where(hold_expires_at: ..Time.current))
  }

  # Number, buyer name or an item's name or code (D187); scoped by the caller to one seller.
  def self.search(query)
    query = query.to_s.strip
    return all if query.empty?

    like = "%#{sanitize_sql_like(query.downcase)}%"
    line_match = OrderLine.joins(:stock_item).where("order_lines.order_id = orders.id")
      .where("LOWER(order_lines.description) LIKE :like OR LOWER(stock_items.code) LIKE :like", like: like)
    where("LOWER(orders.reference) LIKE :like OR LOWER(orders.buyer_name) LIKE :like", like: like).or(where("EXISTS (#{line_match.to_sql})"))
  end

  def open? = OPEN_STATES.include?(state)
  def pickup? = delivery_method == "pickup"
  def shipping? = delivery_method == "shipping"
  def unpaid? = payment_state == "unpaid"
  def fully_paid? = %w[ paid overpaid ].include?(payment_state)

  def active_lines = lines.select(&:active?)
  def lines_cents = active_lines.sum(&:total_cents)
  def total_cents = [ lines_cents + shipping_cents - discount_cents, 0 ].max

  def shipping_lines = ADDRESS_FIELDS.map { shipping_address&.dig(it) }.compact_blank
  def recipient_name = shipping_address&.dig("recipient").presence || buyer_name
  def address_lines = ADDRESS_FIELDS.drop(1).map { shipping_address&.dig(it) }.compact_blank

  # Copies one of the buyer's addresses (D182): later edits to the buyer never change it.
  def ship_to!(address)
    raise ArgumentError, "Choose one of #{buyer_name}'s addresses." unless address && address.buyer_id == buyer_id

    self.delivery_method = "shipping"
    self.shipping_address = address.slice(*ADDRESS_FIELDS).merge("label" => address.label)
    save!
    address.update_column(:last_used_at, Time.current)
  end

  # Rands in the forms, cents in the database; blank is 0 and nonsense is -1 (invalid).
  def self.cents(value)
    value = value.to_s.delete(" ,R").strip
    value.empty? ? 0 : (BigDecimal(value) * 100).round.to_i
  rescue ArgumentError
    -1
  end

  def shipping=(value)
    self.shipping_cents = Order.cents(value)
  end

  def discount=(value)
    self.discount_cents = Order.cents(value)
  end

  def shipping = shipping_cents / 100.0
  def discount = discount_cents / 100.0

  private
    def assign_reference
      return if reference.present? || seller.nil?

      self.number = seller.class.connection.select_value(
        seller.class.sanitize_sql_array([ "UPDATE sellers SET last_order_number = last_order_number + 1 WHERE id = ? RETURNING last_order_number", seller_id ])
      ).to_i
      self.reference = format("O-%04d", number)
    end
end
