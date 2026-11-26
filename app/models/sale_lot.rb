# One auction lot (LS02, LS03, D211–D213): a stock item and a quantity, numbered within its
# session. Opening it holds the units for the session; a win swaps that for the winner's
# hold, which lasts through the payment deadline and the backup window, so a missed payment
# leaves the stock held while the seller offers it to the backup bidder, relists it or
# returns it. The winner and price stay on the lot after a transfer.
class SaleLot < ApplicationRecord
  STATES = %w[ queued open won passed returned relisted ].freeze

  belongs_to :sale_session
  belongs_to :stock_item
  belongs_to :stock_location
  belongs_to :stock_hold, optional: true
  belongs_to :winner_buyer, class_name: "Buyer", optional: true
  belongs_to :winner_alias, class_name: "BuyerAlias", optional: true
  belongs_to :backup_buyer, class_name: "Buyer", optional: true
  belongs_to :backup_alias, class_name: "BuyerAlias", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :settled_by, class_name: "User", optional: true
  has_many :order_lines, dependent: :nullify

  enum :state, STATES.index_by(&:itself), validate: true, default: "queued"

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { equal_to: 1, message: "must be 1 for a specimen" }, if: -> { stock_item&.specimen? }

  delegate :seller, to: :sale_session

  def label = "Lot #{number}"
  def reference = "#{sale_session.name.truncate(60)} · #{label}"
  def transferred? = transferred_at.present?
  def holder_name = transferred? ? backup_name : winner_name
  def holder_price_cents = transferred? ? backup_bid_cents : price_cents
  def backup? = backup_name.present?
  def payment_missed? = won? && payment_due_at.past? && !paid?
  def holding? = won? && stock_hold&.current?
  def offer_to_backup? = payment_missed? && holding? && backup? && !transferred?

  # Closeout (D219–D223): the line holding this lot's current hold, and who it's for.
  def order_line = stock_hold_id && order_lines.find { it.active? && it.stock_hold_id == stock_hold_id }
  def paid? = order_line&.order&.any_payment? || false
  def closeout_pending? = holding? && order_line.nil?
  def closeout_label = "#{label} · #{stock_item.name}"
  def closeout_alias = transferred? ? backup_alias : winner_alias
  def closeout_buyer = (transferred? ? backup_buyer : winner_buyer) || closeout_alias&.buyer.then { it unless it&.deleted? }
  def closeout_unit_cents = holder_price_cents / quantity

  def open!(member:)
    transaction do
      sale_session.lock!
      lock!
      return self if open?
      raise SaleSession::Refused, "The session isn't live." unless sale_session.live?
      raise SaleSession::Refused, "#{label} has already been resolved." unless queued?
      raise SaleSession::Refused, "Resolve #{sale_session.lots.open.first.label} first." if sale_session.lots.open.exists?

      hold = ledger(member).hold!(quantity: quantity, location: stock_location, reference: reference, held_for: "Bidding", pinned: true,
                                  expires_at: sale_session.hold_until(sale_session.payment_due_from))
      update!(state: "open", stock_hold: hold, opened_at: Time.current)
      Audit.record("sale_lot.opened", actor: member, target: self, details: { reference: reference })
    end
    self
  end

  # The session's hold becomes the winner's in one transaction (D212).
  def win!(member:, winner:, price_cents:, backup: nil, backup_bid_cents: nil)
    raise SaleSession::Refused, "Choose or type the winner." unless winner
    raise SaleSession::Refused, "Enter the winning bid in rands." if price_cents.nil? || price_cents.negative?
    raise SaleSession::Refused, "Enter the backup bid in rands." if backup && (backup_bid_cents.nil? || backup_bid_cents.negative?)
    raise SaleSession::Refused, "The backup bidder can't be the winner." if backup && backup == winner
    refuse_uneven!(price_cents)
    refuse_uneven!(backup_bid_cents) if backup

    transaction do
      lock!
      return self if won?
      raise SaleSession::Refused, "#{label} isn't open." unless open?

      due = sale_session.payment_due_from
      hold = swap_hold!(member, winner, SaleSession.holder_name(winner), due)
      update!(state: "won", stock_hold: hold, winner_buyer: winner[:buyer], winner_alias: winner[:buyer_alias], winner_name: SaleSession.holder_name(winner), price_cents: price_cents,
              backup_buyer: backup&.dig(:buyer), backup_alias: backup&.dig(:buyer_alias), backup_name: backup && SaleSession.holder_name(backup), backup_bid_cents: (backup_bid_cents if backup),
              payment_due_at: due, resolved_at: Time.current, resolved_by: member)
      Audit.record("sale_lot.won", actor: member, target: self, details: { reference: reference, price_cents: price_cents, backup: backup.present? })
    end
    self
  end

  # Passing releases the lot's hold once (LS02).
  def pass!(member:)
    transaction do
      lock!
      return self if passed?
      raise SaleSession::Refused, "#{label} isn't open." unless open?

      ledger(member).release!(stock_hold)
      update!(state: "passed", resolved_at: Time.current, resolved_by: member)
      Audit.record("sale_lot.passed", actor: member, target: self, details: { reference: reference })
    end
    self
  end

  # After a missed payment, within the backup window: the backup bidder gets the units at
  # their bid with a fresh deadline (LS03, D213). There's still only one hold.
  def transfer_to_backup!(member:)
    transaction do
      lock!
      return self if transferred?
      raise SaleSession::Refused, "#{label} can go to the backup bidder only after a missed payment, within the backup window." unless offer_to_backup?

      # An ordered win leaves the winner's order first (D223); the hold goes in the swap.
      order_line&.then { it.order.drop_sale_line!(it, reason: "Payment missed", member: member) }
      due = sale_session.payment_due_from
      hold = swap_hold!(member, { buyer: backup_buyer, buyer_alias: backup_alias }, backup_name, due)
      update!(stock_hold: hold, payment_due_at: due, transferred_at: Time.current, settled_by: member)
      Audit.record("sale_lot.transferred", actor: member, target: self, details: { reference: reference, price_cents: backup_bid_cents })
      closeout_buyer&.then { sale_session.open_order_for(it)&.add_sale_line!(self, member: member) }
    end
    self
  end

  # The units go back up as a new lot in the same session (D213).
  def relist!(member:)
    transaction do
      lock!
      raise SaleSession::Refused, "Only a won lot can be relisted." unless won?
      raise SaleSession::Refused, "The session is closed; return the stock instead." if sale_session.closed?

      settle!(member, "relisted")
      sale_session.add_lot!(stock_item: stock_item, location: stock_location, quantity: quantity)
    end
  end

  def return_to_stock!(member:)
    transaction do
      lock!
      return self if returned?
      raise SaleSession::Refused, "Only a won lot can be returned to stock." unless won?

      settle!(member, "returned")
    end
    self
  end

  # Its order line was cancelled, which let the hold go: the plant is back in stock.
  def order_line_cancelled!(member)
    with_lock do
      next unless won? && !stock_hold&.current?

      update!(state: "returned", settled_at: Time.current, settled_by: member)
      Audit.record("sale_lot.returned", actor: member, target: self, details: { reference: reference, order_line_cancelled: true })
    end
  end

  # Won lots whose hold ran out at the end of the backup window are back in stock (D213).
  def self.settle_expired!
    won.joins(:stock_hold).where(stock_holds: { state: "expired" }).update_all(state: "returned", settled_at: Time.current, updated_at: Time.current)
  end

  private
    # A lot's bid is for all its plants; the order line needs an exact price each.
    def refuse_uneven!(cents)
      return if quantity == 1 || cents.nil? || (cents % quantity).zero?

      even = cents - (cents % quantity)
      raise SaleSession::Refused, "R#{format('%.2f', cents / 100.0)} doesn't split evenly over #{quantity} plants; enter R#{format('%.2f', even / 100.0)} or R#{format('%.2f', (even + quantity) / 100.0)}."
    end

    def ledger(member) = Stock::Ledger.new(stock_item, member: member)

    def swap_hold!(member, holder, name, due)
      ledger = ledger(member)
      StockItem.transaction do
        ledger.release!(stock_hold) if stock_hold&.active?
        ledger.hold!(quantity: quantity, location: stock_location, reference: reference, expires_at: sale_session.hold_until(due), held_for: name, buyer: holder[:buyer], buyer_alias: holder[:buyer_alias])
      end
    end

    def settle!(member, state)
      ledger(member).release!(stock_hold) if stock_hold&.current?
      update!(state: state, settled_at: Time.current, settled_by: member)
      Audit.record("sale_lot.#{state}", actor: member, target: self, details: { reference: reference })
    end
end
