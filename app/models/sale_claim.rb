# A group claim (LS04, D214, D215): held for the claimer through the payment deadline and
# the session's backup window, or waiting in line. Nothing on the waitlist is reserved until
# the host offers returned stock to the next person (AT24).
class SaleClaim < ApplicationRecord
  STATES = %w[ held waitlisted returned removed ended ].freeze

  belongs_to :claim_item, class_name: "SaleClaimItem", foreign_key: :sale_claim_item_id, inverse_of: :claims
  belongs_to :buyer, optional: true
  belongs_to :buyer_alias, optional: true
  belongs_to :stock_hold, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :settled_by, class_name: "User", optional: true

  enum :state, STATES.index_by(&:itself), validate: true

  validates :holder_name, presence: true, length: { maximum: 120 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :message_reference, length: { maximum: 120 }

  delegate :sale_session, :stock_item, :stock_location, :price_cents, to: :claim_item

  def payment_missed? = held? && payment_due_at.past?

  # Holds the units for the claimer (D214); the caller holds the item's lock.
  def hold!(member)
    session = sale_session
    due = session.payment_due_from
    hold = Stock::Ledger.new(stock_item, member: member).hold!(quantity: quantity, location: stock_location, reference: "#{session.name.truncate(60)} · Claim",
                                                               held_for: holder_name, buyer: buyer, buyer_alias: buyer_alias, expires_at: session.hold_until(due))
    update!(state: "held", stock_hold: hold, payment_due_at: due)
  end

  # The next person waiting gets returned stock, on a tap (D215).
  def offer!(member:)
    claim_item.with_lock do
      reload
      return self if held?
      raise SaleSession::Refused, "#{holder_name} isn't waiting any more." unless waitlisted?
      raise SaleSession::Refused, "Offer to #{claim_item.next_waiting.holder_name} first; they're next in line." unless claim_item.next_waiting == self
      raise SaleSession::Refused, "There isn't enough stock back yet." unless claim_item.available >= quantity

      hold!(member)
      Audit.record("sale_claim.offered", actor: member, target: self, details: { quantity: quantity, position: position })
    end
    self
  end

  def return_to_stock!(member:) = settle!(member, "returned", from: "held")
  def remove!(member:) = settle!(member, "removed", from: "waitlisted")

  def self.settle_expired!
    held.joins(:stock_hold).where(stock_holds: { state: "expired" }).update_all(state: "returned", settled_at: Time.current, updated_at: Time.current)
  end

  private
    def settle!(member, state, from:)
      with_lock do
        return self if self.state == state
        raise SaleSession::Refused, "That claim is #{self.state}." unless self.state == from

        Stock::Ledger.new(stock_item, member: member).release!(stock_hold) if stock_hold&.current?
        update!(state: state, settled_at: Time.current, settled_by: member)
        Audit.record("sale_claim.#{state}", actor: member, target: self, details: { quantity: quantity })
      end
      self
    end
end
