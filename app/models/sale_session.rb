# A live sale (LS01, D209–D211, D216): bidding stays in the WhatsApp group and the host
# captures results here. A session can't go live without its payment deadline and backup
# window (D14, D210), both in hours: the deadline counts from when a lot is won or a claim
# taken, and the hold stays through the backup window after it.
class SaleSession < ApplicationRecord
  class Refused < StandardError; end

  STATUSES = %w[ draft live paused closed ].freeze
  MAX_HOURS = 720

  belongs_to :seller
  belongs_to :host_member, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :lots, -> { order(:number) }, class_name: "SaleLot", dependent: :delete_all, inverse_of: :sale_session
  has_many :claim_items, -> { order(:id) }, class_name: "SaleClaimItem", dependent: :destroy, inverse_of: :sale_session
  has_many :claims, through: :claim_items
  has_many :orders, dependent: :nullify

  enum :status, STATUSES.index_by(&:itself), validate: true, default: "draft"

  normalizes :name, :channel, with: ->(value) { value.squish.presence }

  validates :name, presence: true, length: { maximum: 80 }
  validates :channel, length: { maximum: 80 }
  validates :payment_hours, :backup_hours, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_HOURS }, allow_nil: true
  validate :host_is_a_member

  scope :newest_first, -> { order(Arel.sql("COALESCE(sale_sessions.starts_at, sale_sessions.created_at) DESC"), id: :desc) }
  scope :running, -> { where(status: %w[ live paused ]) }

  # The seller's last timings prefill a new session's form, never a platform default (D210).
  def self.prefill_for(seller)
    last = seller.sale_sessions.where.not(payment_hours: nil).order(:created_at).last
    seller.sale_sessions.new(payment_hours: last&.payment_hours, backup_hours: last&.backup_hours)
  end

  # Results join the buyer's unpaid order for this session, or a new one (D219, D220).
  def open_order_for(buyer) = orders.open.where(buyer: buyer, payment_state: "unpaid").order(:id).first

  def closeout = Closeout.new(self)

  def timings_set? = payment_hours.present? && backup_hours.present?
  def running? = live? || paused?
  def open_lot = lots.find(&:open?)
  def payment_due_from(time = Time.current) = time + payment_hours.hours
  def hold_until(payment_due_at) = payment_due_at + backup_hours.hours

  def go_live!(member)
    change_status!(member, "live", from: %w[ draft paused ]) do
      raise Refused, "Set the payment deadline and backup window before going live." unless timings_set?

      self.went_live_at ||= Time.current
    end
  end

  def pause!(member) = change_status!(member, "paused", from: %w[ live ])

  # Closing needs no lot open (D216). Unopened lots stay unsold; the waitlist ends.
  def close!(member)
    change_status!(member, "closed", from: %w[ draft live paused ]) do
      raise Refused, "Resolve #{open_lot.label} before closing the session." if open_lot

      SaleClaim.where(sale_claim_item_id: claim_items.select(:id)).waitlisted.update_all(state: "ended", settled_at: Time.current, updated_at: Time.current)
      self.closed_at = Time.current
    end
  end

  def add_lot!(stock_item:, location:, quantity:)
    raise Refused, "This session is closed." if closed?
    raise Refused, "That item belongs to another business." unless stock_item&.seller_id == seller_id && !stock_item.archived?
    raise Refused, "Choose a location." unless location&.seller_id == seller_id

    transaction do
      lock!
      lots.create!(number: lots.maximum(:number).to_i + 1, stock_item: stock_item, stock_location: location, quantity: quantity)
    end
  end

  def add_claim_item!(stock_item:, location:, price_cents:)
    raise Refused, "This session is closed." if closed?
    raise Refused, "That item belongs to another business." unless stock_item&.seller_id == seller_id && !stock_item.archived?
    raise Refused, "Choose a location." unless location&.seller_id == seller_id
    raise Refused, "Enter the claim price in rands." if price_cents.nil? || price_cents.negative?

    claim_items.create!(stock_item: stock_item, stock_location: location, price_cents: price_cents)
  end

  # Who a result or claim is for (D172, D212): "buyer:12", "alias:7", or a name typed by the
  # host, which becomes an alias in this session's group (reused when the same name is typed
  # again for the same group).
  def holder(choice, name, member:)
    kind, id = choice.to_s.split(":", 2)
    case kind
    when "buyer" then { buyer: seller.buyers.active.find(id) }
    when "alias" then { buyer_alias: seller.buyer_aliases.find(id) }
    else
      name = name.to_s.squish
      return if name.empty?

      existing = seller.buyer_aliases.where("LOWER(name) = ?", name.downcase).find_by(group_name: channel)
      { buyer_alias: existing || seller.buyer_aliases.create!(name: name, group_name: channel, created_by: member) }
    end
  end

  def self.holder_name(holder) = holder[:buyer]&.name || holder[:buyer_alias].label

  private
    def change_status!(member, status, from:)
      transaction do
        lock!
        return self if self.status == status
        raise Refused, "A #{self.status} session can't be #{status == 'live' ? 'made live' : status}." unless from.include?(self.status)

        yield if block_given?
        update!(status: status)
        Audit.record("sale_session.#{status}", actor: member, target: self)
      end
      self
    end

    def host_is_a_member
      errors.add(:host_member, "must be a member of this business") if host_member_id && !seller.memberships.exists?(user_id: host_member_id)
    end
end
