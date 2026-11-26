require "test_helper"

class SaleCloseoutTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @owner = users(:owner)
    @shelf = @seller.stock_locations.create!(name: "Shelf")
    @monstera = stock(kind: "specimen", name: "Monstera", code: "MON-1", quantity: 1)
    @alocasia = stock(kind: "specimen", name: "Alocasia", code: "ALO-1", quantity: 1)
    @pothos = stock(kind: "batch", name: "Pothos", code: "POT-1", quantity: 5)
    @sam = @seller.buyers.create!(name: "Sam Dube", phone: "+27821110000")
    @lee = @seller.buyers.create!(name: "Lee Naidoo", phone: "+27821110001")
    @session = @seller.sale_sessions.create!(name: "Sunday auction", channel: "Aroid Club", created_by: @owner, payment_hours: 24, backup_hours: 12)
    @session.go_live!(@owner)
  end

  test "three results for one buyer become one order with their holds, and a second tap adds nothing" do
    first = win(@monstera, @sam, 45_000)
    second = win(@alocasia, @sam, 30_000)
    claim = claim(@pothos, @sam, 2)
    holds = [ first, second, claim ].map(&:stock_hold_id)

    assert_equal 3, @session.closeout.create_orders!(@owner)
    order = @session.orders.sole
    assert_equal [ "reserved", "live_sale", @sam ], [ order.state, order.source, order.buyer ]
    assert_equal holds.sort, order.lines.map(&:stock_hold_id).sort
    assert_equal 45_000 + 30_000 + 2 * 8_500, order.total_cents
    assert_in_delta first.stock_hold.expires_at, order.hold_expires_at, 1
    assert_equal holds.sort, StockHold.current.where(stock_item: [ @monstera, @alocasia, @pothos ]).pluck(:id).sort, "nothing released and held again"

    assert_no_difference -> { OrderLine.count } do
      assert_equal 0, @session.closeout.create_orders!(@owner)
    end
  end

  test "an unlinked alias waits, a buyer with the same name isn't matched, and linking lets it through" do
    @seller.buyers.create!(name: "Ana", phone: "+27821110002")
    win(@monstera, nil, 45_000, name: "Ana")
    closeout = @session.closeout
    assert_equal 1, closeout.unresolved.size
    assert_equal 0, closeout.create_orders!(@owner)
    assert_empty @session.orders

    closeout.unresolved.keys.sole.update!(buyer: @sam)
    assert_equal 1, @session.closeout.create_orders!(@owner)
    assert_equal @sam, @session.orders.sole.buyer
  end

  test "a payment keeps the result from showing as missed" do
    lot = win(@monstera, @sam, 45_000)
    @session.closeout.create_orders!(@owner)
    order = @session.orders.sole
    order.record_payment!(amount_cents: 45_000, method: "eft", paid_on: Date.current, member: @owner)

    travel_to 2.days.from_now do
      assert_not lot.reload.payment_missed?
      assert lot.stock_hold.reload.pinned?
      ExpireStockHoldsJob.perform_now
      assert lot.reload.won?
      assert_includes @session.closeout.ready_to_pack, order
    end
  end

  test "moving a missed payment to the backup cancels the winner's line and puts the backup's on their order" do
    lot = win(@monstera, @sam, 45_000, backup: @lee, backup_bid_cents: 40_000)
    claim(@pothos, @lee, 1)
    @session.closeout.create_orders!(@owner)
    sam_order = @session.orders.find_by!(buyer: @sam)
    lee_order = @session.orders.find_by!(buyer: @lee)

    travel_to 25.hours.from_now do
      assert_equal [ lot ], @session.closeout.backup_offers
      lot.reload.transfer_to_backup!(member: @owner)
      assert_equal [ "cancelled", "Payment missed" ], sam_order.lines.sole.slice(:state, :cancel_reason).values
      assert_equal 1, @monstera.holds.current.count
      line = lee_order.lines.find_by!(sale_lot: lot)
      assert_equal [ 40_000, lot.stock_hold_id ], [ line.unit_price_cents, line.stock_hold_id ]
      assert_equal "Sam Dube", lot.winner_name
    end
  end

  test "splitting and cancelling an unpaid order record the previous total and reason; a paid one refuses" do
    win(@monstera, @sam, 45_000)
    lot = win(@alocasia, @sam, 30_000)
    @session.closeout.create_orders!(@owner)
    order = @session.orders.sole
    alocasia = order.lines.find_by!(sale_lot: lot)

    split = order.split!(line_ids: [ alocasia.id ], reason: "Ships later", member: @owner)
    assert_equal [ 45_000, 30_000 ], [ order.reload.total_cents, split.total_cents ]
    audit = AuditEvent.where(action: "order.split").last
    assert_equal [ 75_000, 45_000, "Ships later" ], audit.details.values_at("from_cents", "to_cents", "reason")
    assert alocasia.reload.held?

    split.remove_line!(alocasia, reason: "Changed their mind", member: @owner)
    assert lot.reload.returned?
    assert_equal 1, Stock::Ledger.new(@alocasia, member: @owner).position(@shelf).available
    assert_equal [ 30_000, 0 ], AuditEvent.where(action: "order.line_cancelled").last.details.values_at("from_cents", "to_cents")

    order.record_payment!(amount_cents: 10_000, method: "eft", paid_on: Date.current, member: @owner)
    assert_raises(Order::Reserving::Refused) { order.split!(line_ids: [ order.lines.first.id ], reason: "x", member: @owner) }
    assert_raises(Order::Reserving::Refused) { order.remove_line!(order.lines.first, reason: "x", member: @owner) }
  end

  test "a multi-plant lot's bid must split evenly into a price each" do
    lot = @session.add_lot!(stock_item: @pothos, location: @shelf, quantity: 3)
    lot.open!(member: @owner)
    error = assert_raises(SaleSession::Refused) { lot.win!(member: @owner, winner: { buyer: @sam }, price_cents: 10_000) }
    assert_match "R99.99 or R100.02", error.message
    lot.win!(member: @owner, winner: { buyer: @sam }, price_cents: 9_999)
    @session.closeout.create_orders!(@owner)
    assert_equal [ 3, 3_333 ], @session.orders.sole.lines.sole.slice(:quantity, :unit_price_cents).values
  end

  private
    def stock(kind:, name:, code:, quantity:)
      @seller.stock_items.create!(kind: kind, name: name, code: code, price_cents: 8_500).tap { Stock::Ledger.new(it, member: @owner).receive!(quantity: quantity, location: @shelf) }
    end

    def win(item, buyer, cents, name: nil, backup: nil, backup_bid_cents: nil)
      lot = @session.add_lot!(stock_item: item, location: @shelf, quantity: 1)
      lot.open!(member: @owner)
      winner = buyer ? { buyer: buyer } : @session.holder("", name, member: @owner)
      lot.win!(member: @owner, winner: winner, price_cents: cents, backup: (backup && { buyer: backup }), backup_bid_cents: backup_bid_cents)
    end

    def claim(item, buyer, quantity)
      @claim_item ||= @session.add_claim_item!(stock_item: item, location: @shelf, price_cents: 8_500)
      @claim_item.claim!(member: @owner, holder: { buyer: buyer }, quantity: quantity)
    end
end
