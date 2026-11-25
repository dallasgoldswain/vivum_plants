# A plant offered for "first to say MINE" claims in a live session, at a fixed price
# (LS04, D214). Claims hold stock in arrival order; once stock runs out, or anyone is already
# waiting, a claim joins the numbered waitlist instead (D215).
class SaleClaimItem < ApplicationRecord
  belongs_to :sale_session
  belongs_to :stock_item
  belongs_to :stock_location
  has_many :claims, -> { order(:id) }, class_name: "SaleClaim", dependent: :delete_all, inverse_of: :claim_item

  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(removed_at: nil) }

  delegate :seller, to: :sale_session

  def removed? = removed_at.present?
  def available = Stock::Ledger.new(stock_item, member: nil).position(stock_location).available
  def waitlist = claims.waitlisted.reorder(:position)
  def next_waiting = waitlist.first

  # Stock has come back for the first person waiting (D215): the host offers it on a tap.
  def offer_ready? = next_waiting.present? && available >= next_waiting.quantity

  def claim!(member:, holder:, quantity:, message_reference: nil, waitlist: true)
    raise SaleSession::Refused, "Choose or type who's claiming." unless holder
    raise SaleSession::Refused, "Enter a quantity of 1 or more." unless quantity.to_i.positive?
    raise SaleSession::Refused, "A specimen is one plant; claim 1." if stock_item.specimen? && quantity.to_i != 1

    transaction do
      lock!
      raise SaleSession::Refused, "The session isn't taking claims." unless sale_session.reload.live?
      raise SaleSession::Refused, "This plant has been taken off claims." if removed?

      claim = claims.new(quantity: quantity.to_i, message_reference: message_reference.to_s.squish.presence, buyer: holder[:buyer], buyer_alias: holder[:buyer_alias],
                         holder_name: SaleSession.holder_name(holder), created_by: member)
      stock_item.lock!
      if claims.waitlisted.none? && available >= claim.quantity
        claim.hold!(member)
      elsif waitlist
        claim.update!(state: "waitlisted", position: claims.maximum(:position).to_i + 1)
      else
        raise SaleSession::Refused, "Only #{available} available, so #{claim.holder_name}'s claim can't be held."
      end
      Audit.record("sale_claim.#{claim.state}", actor: member, target: claim, details: { quantity: claim.quantity, position: claim.position })
      claim
    end
  end

  # No new claims; claims already held stay, and the waitlist ends.
  def remove!(member:)
    transaction do
      lock!
      return self if removed?

      claims.waitlisted.update_all(state: "ended", settled_at: Time.current, updated_at: Time.current)
      update!(removed_at: Time.current)
      Audit.record("sale_claim_item.removed", actor: member, target: self)
    end
    self
  end
end
