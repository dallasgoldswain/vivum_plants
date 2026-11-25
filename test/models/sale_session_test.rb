require "test_helper"

class SaleSessionTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @owner = users(:owner)
    @shelf = @seller.stock_locations.create!(name: "Shelf")
    @monstera = stock(kind: "specimen", name: "Monstera", code: "MON-1", quantity: 1)
    @pothos = stock(kind: "batch", name: "Pothos", code: "POT-1", quantity: 3)
    @session = @seller.sale_sessions.create!(name: "Sunday auction", channel: "Aroid Club", created_by: @owner)
  end

  test "a session goes live only with both timings, and the next one prefills them" do
    assert_raises(SaleSession::Refused) { @session.go_live!(@owner) }
    @session.update!(payment_hours: 24, backup_hours: 12)
    @session.go_live!(@owner)
    assert @session.live?

    prefill = SaleSession.prefill_for(@seller)
    assert_equal [ 24, 12 ], [ prefill.payment_hours, prefill.backup_hours ]
  end

  test "opening holds the lot; winning leaves one hold for the winner until the deadline and backup window" do
    live!
    lot = @session.add_lot!(stock_item: @monstera, location: @shelf, quantity: 1)
    lot.open!(member: @owner)
    assert_raises(Stock::Ledger::Refused) { ledger(@monstera).hold!(quantity: 1, location: @shelf, held_for: "DM claim", expires_at: 1.day.from_now) }

    winner = @session.holder("", "Sam", member: @owner)
    travel_to 1.minute.from_now do
      lot.win!(member: @owner, winner: winner, price_cents: 45_000, backup: @session.holder("", "Lee", member: @owner), backup_bid_cents: 40_000)
      lot.win!(member: @owner, winner: winner, price_cents: 45_000)
    end
    assert_equal 1, @monstera.holds.current.count
    hold = @monstera.holds.current.sole
    assert_equal "Sam (Aroid Club)", lot.reload.winner_name
    assert_equal winner[:buyer_alias], hold.buyer_alias
    assert_in_delta lot.payment_due_at + 12.hours, hold.expires_at, 1
    assert_equal @session.holder("", "sam", member: @owner)[:buyer_alias], winner[:buyer_alias]
  end

  test "passing releases once" do
    live!
    lot = @session.add_lot!(stock_item: @pothos, location: @shelf, quantity: 2)
    lot.open!(member: @owner)
    assert_difference -> { StockMovement.where(kind: "release").count } => 1 do
      lot.pass!(member: @owner)
      lot.pass!(member: @owner)
    end
    assert_equal 3, ledger(@pothos).position(@shelf).available
  end

  test "a missed payment keeps the hold for the backup, then the stock returns" do
    live!
    lot = won_lot(backup: true)
    assert_not lot.offer_to_backup?

    travel_to 25.hours.from_now do
      assert lot.payment_missed?
      assert_equal 0, ledger(@monstera).position(@shelf).available
      lot.transfer_to_backup!(member: @owner)
      assert_equal "Lee (Aroid Club)", lot.holder_name
      assert_equal 40_000, lot.holder_price_cents
      assert_equal "Sam (Aroid Club)", lot.winner_name
      assert_equal 1, @monstera.holds.current.count
    end

    travel_to 70.hours.from_now do
      ExpireStockHoldsJob.perform_now
      assert lot.reload.returned?
      assert_equal 1, ledger(@monstera).position(@shelf).available
    end
  end

  test "a won lot can be relisted as a new lot or returned" do
    live!
    relisted = won_lot.relist!(member: @owner)
    assert_equal 2, relisted.number
    assert relisted.queued?
    assert_equal 1, ledger(@monstera).position(@shelf).available
  end

  test "claims hold in order, then queue on the waitlist until the host offers returned stock" do
    live!
    item = @session.add_claim_item!(stock_item: @pothos, location: @shelf, price_cents: 8_500)
    first = item.claim!(member: @owner, holder: @session.holder("", "Ana", member: @owner), quantity: 2, message_reference: "10:02")
    second = item.claim!(member: @owner, holder: @session.holder("", "Ben", member: @owner), quantity: 2)
    third = item.claim!(member: @owner, holder: @session.holder("", "Cy", member: @owner), quantity: 1)
    assert first.held?
    assert_equal [ "waitlisted", 1 ], [ second.state, second.position ]
    assert_equal [ "waitlisted", 2 ], [ third.state, third.position ], "nobody jumps the line while someone waits"
    assert_not item.offer_ready?

    assert_raises(SaleSession::Refused) { third.offer!(member: @owner) }
    first.return_to_stock!(member: @owner)
    assert item.offer_ready?
    assert_equal 3, ledger(@pothos).position(@shelf).available, "returned stock isn't reserved until offered"
    second.offer!(member: @owner)
    assert second.reload.held?
    assert_equal 1, ledger(@pothos).position(@shelf).available
  end

  test "a paused session takes no claims or lots; closing needs no open lot and ends the waitlist" do
    live!
    item = @session.add_claim_item!(stock_item: @monstera, location: @shelf, price_cents: 1_000)
    item.claim!(member: @owner, holder: @session.holder("", "Ana", member: @owner), quantity: 1)
    waiting = item.claim!(member: @owner, holder: @session.holder("", "Ben", member: @owner), quantity: 1)
    lot = @session.add_lot!(stock_item: @pothos, location: @shelf, quantity: 1)
    @session.pause!(@owner)
    assert_raises(SaleSession::Refused) { item.claim!(member: @owner, holder: @session.holder("", "Cy", member: @owner), quantity: 1) }
    assert_raises(SaleSession::Refused) { lot.open!(member: @owner) }

    @session.go_live!(@owner)
    lot.open!(member: @owner)
    assert_raises(SaleSession::Refused) { @session.close!(@owner) }
    lot.pass!(member: @owner)
    @session.close!(@owner)
    assert waiting.reload.ended?
  end

  test "a lot on a held specimen can't open" do
    live!
    ledger(@monstera).hold!(quantity: 1, location: @shelf, held_for: "Thandi", expires_at: 1.day.from_now)
    lot = @session.add_lot!(stock_item: @monstera, location: @shelf, quantity: 1)
    assert_raises(Stock::Ledger::Refused) { lot.open!(member: @owner) }
    assert lot.reload.queued?
  end

  private
    def stock(kind:, name:, code:, quantity:)
      @seller.stock_items.create!(kind: kind, name: name, code: code).tap { ledger(it).receive!(quantity: quantity, location: @shelf) }
    end

    def ledger(item) = Stock::Ledger.new(item, member: @owner)

    def live!
      @session.update!(payment_hours: 24, backup_hours: 12)
      @session.go_live!(@owner)
    end

    def won_lot(backup: false)
      lot = @session.add_lot!(stock_item: @monstera, location: @shelf, quantity: 1)
      lot.open!(member: @owner)
      lot.win!(member: @owner, winner: @session.holder("", "Sam", member: @owner), price_cents: 45_000,
               backup: (@session.holder("", "Lee", member: @owner) if backup), backup_bid_cents: 40_000)
    end
end
