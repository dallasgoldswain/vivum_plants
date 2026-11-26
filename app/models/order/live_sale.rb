# Orders made from a live sale session in Closeout (SC01, SC02, D219–D225). Each line comes
# from one won lot or held claim and takes over that result's hold, so its payment deadline
# and backup window carry on unchanged (D222). Unpaid orders can be split; part-paid and
# paid ones go through refunds and returns instead (D225).
module Order::LiveSale
  extend ActiveSupport::Concern

  included do
    belongs_to :sale_session, optional: true
  end

  def live_sale? = source == "live_sale"

  # A won lot or held claim joins the order with its hold; the unique hold on order lines
  # keeps a result off two lines.
  def add_sale_line!(result, member:)
    changing(member, [ result.stock_item ], lines_change: true) do
      raise Order::Reserving::Refused, "#{result.closeout_label} is no longer held." unless result.stock_hold&.current?

      line = lines.create!(stock_item: result.stock_item, quantity: result.quantity, description: result.closeout_label.truncate(160),
                           agreed_price_cents: result.closeout_unit_cents, unit_price_cents: result.closeout_unit_cents, stock_hold: result.stock_hold,
                           sale_lot: (result if result.is_a?(SaleLot)), sale_claim: (result if result.is_a?(SaleClaim)))
      result.stock_hold.update!(pinned: true) if any_payment?
      follow_hold_expiry!
      Audit.record("order.sale_line_added", actor: member, target: self, details: { line_id: line.id, reference: result.closeout_label, unit_price_cents: line.unit_price_cents })
      line
    end
  end

  # Chosen lines move, with their holds, to a new order for the same buyer (D224).
  def split!(line_ids:, reason:, member:)
    changing(member, lines_change: true) do
      raise Order::Reserving::Refused, "#{reference} has payments, so it can't be split; record a refund or return instead." if any_payment?
      raise Order::Reserving::Refused, "Give a reason for splitting the order." if reason.to_s.strip.empty?

      moving = lines.active.where(id: Array(line_ids)).to_a
      raise Order::Reserving::Refused, "Choose the lines to move." if moving.empty?
      raise Order::Reserving::Refused, "Leave at least one line on #{reference}." if moving.size >= lines.active.count

      before = total_cents
      split = seller.orders.create!(buyer: buyer, source: source, sale_session: sale_session, state: state, hold_expires_at: hold_expires_at,
                                    delivery_method: delivery_method, shipping_address: shipping_address, created_by: member)
      OrderLine.where(id: moving.map(&:id)).update_all(order_id: split.id, updated_at: Time.current)
      lines.reset
      [ self, split ].each(&:follow_hold_expiry!)
      Audit.record("order.split", actor: member, target: self, details: { into: split.reference, line_ids: moving.map(&:id), from_cents: before, to_cents: total_cents, reason: reason.squish })
      Audit.record("order.split_from", actor: member, target: split, details: { from: reference, to_cents: split.total_cents, reason: reason.squish })
      split
    end
  end

  # Move to backup (D223): the winner's line is cancelled and keeps its hold, which the
  # lot then passes to the backup bidder.
  def drop_sale_line!(line, reason:, member:)
    changing(member, lines_change: true) do
      line.lock!
      next line unless line.active?

      before = total_cents
      line.update!(state: "cancelled", cancel_reason: reason)
      lines.reset
      Audit.record("order.line_cancelled", actor: member, target: self, details: { line_id: line.id, reason: reason, from_cents: before, to_cents: total_cents })
      line
    end
  end

  # The order's hold shows the earliest end among its held lines (D222).
  def follow_hold_expiry!
    ends = lines.reload.select { it.active? && it.held? }.map { it.stock_hold.expires_at }.compact
    update!(hold_expires_at: ends.min) if ends.any? && ends.min != hold_expires_at
  end
end
