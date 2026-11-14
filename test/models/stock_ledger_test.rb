require "test_helper"

class StockLedgerTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @member = users(:manager)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @shelf = @seller.stock_locations.create!(name: "Shop shelf")
  end

  test "items get S- codes from a per-seller counter, or the seller's own unique code (D156)" do
    first = @seller.stock_items.create!(kind: "batch", name: "Pothos")
    second = @seller.stock_items.create!(kind: "batch", name: "Hoya")
    other = sellers(:aroid_attic).stock_items.create!(kind: "batch", name: "Hoya")
    assert_equal [ "S-0001", "S-0002", "S-0001" ], [ first.code, second.code, other.code ]
    assert_not @seller.stock_items.new(kind: "batch", name: "X", code: "s-0001").valid?
    assert_equal "MON-01", @seller.stock_items.create!(kind: "batch", name: "Monstera", code: "MON-01").code
  end

  test "receive 5, hold 2, mark 1 unavailable gives 2 available; fulfilling removes 2 (SE02)" do
    item = batch
    ledger.receive!(quantity: 5, location: @greenhouse)
    hold = ledger.hold!(quantity: 2, location: @greenhouse, held_for: "Thandi", expires_at: 1.day.from_now)
    ledger.mark_unavailable!(quantity: 1, location: @greenhouse, reason: "Damaged")
    assert_equal [ 5, 1, 2, 2 ], item.totals.then { [ it.on_hand, it.unavailable, it.held, it.available ] }

    ledger.fulfil!(hold)
    totals = item.reload.totals
    assert_equal [ 3, 0, 2 ], [ totals.on_hand, totals.held, totals.available ]
    assert_equal %w[ receipt hold mark_unavailable fulfil ], item.movements.order(:id).pluck(:kind)
  end

  test "stock never goes negative or below what's held" do
    item = batch
    ledger.receive!(quantity: 3, location: @greenhouse)
    ledger.hold!(quantity: 2, location: @greenhouse, held_for: "Sam", expires_at: 1.hour.from_now)
    assert_raises(Stock::Ledger::Refused) { ledger.lose!(quantity: 2, location: @greenhouse, reason: "Rot") }
    assert_raises(Stock::Ledger::Refused) { ledger.move!(quantity: 4, from: @greenhouse, to: @shelf) }
    assert_raises(Stock::Ledger::Refused) { ledger.count!(counted: 1, location: @greenhouse, reason: "Count") }
    assert_raises(Stock::Ledger::Refused) { ledger.hold!(quantity: 2, location: @greenhouse, held_for: "Lee", expires_at: 1.hour.from_now) }
    assert_equal 3, item.totals.on_hand
  end

  test "moves keep the total and a count records the difference (D160)" do
    item = batch
    ledger.receive!(quantity: 6, location: @greenhouse)
    ledger.move!(quantity: 2, from: @greenhouse, to: @shelf)
    ledger.count!(counted: 5, location: @greenhouse, reason: "Monthly count")
    positions = item.positions.to_h { [ it.location.name, it.saleable ] }
    assert_equal({ "Greenhouse" => 5, "Shop shelf" => 2 }, positions)
    assert_equal 1, item.movements.adjustment.sole.quantity
  end

  test "a specimen is one plant and can only be held once (D159)" do
    item = @seller.stock_items.create!(kind: "specimen", name: "Variegated Monstera")
    ledger(item).receive!(quantity: 1, location: @greenhouse)
    assert_raises(Stock::Ledger::Refused) { ledger(item).receive!(quantity: 1, location: @shelf) }
    ledger(item).hold!(quantity: 1, location: @greenhouse, held_for: "A", expires_at: 1.day.from_now)
    assert_raises(Stock::Ledger::Refused) { ledger(item).hold!(quantity: 1, location: @greenhouse, held_for: "B", expires_at: 1.day.from_now) }
  end

  test "a hold needs a future expiry, and an expired hold frees stock and is recorded once" do
    item = batch
    ledger.receive!(quantity: 1, location: @greenhouse)
    assert_raises(Stock::Ledger::Refused) { ledger.hold!(quantity: 1, location: @greenhouse, held_for: "A", expires_at: nil) }
    hold = ledger.hold!(quantity: 1, location: @greenhouse, held_for: "A", expires_at: 10.minutes.from_now)

    travel 11.minutes do
      assert_equal 1, item.totals.available
      2.times { ExpireStockHoldsJob.perform_now }
      assert hold.reload.expired?
      assert_equal 1, item.movements.expire.count
      assert_raises(Stock::Ledger::Refused) { ledger.fulfil!(hold) }
    end
  end

  test "releasing twice records one release" do
    item = batch
    ledger.receive!(quantity: 2, location: @greenhouse)
    hold = ledger.hold!(quantity: 2, location: @greenhouse, held_for: "A", expires_at: 1.day.from_now)
    ledger.release!(hold)
    ledger.release!(hold.reload)
    assert_equal 1, item.movements.release.count
    assert_equal 2, item.totals.available
  end

  test "moving a plant to stock links a specimen and fulfilling it records the sale on the plant (SE04, D162)" do
    plant = plants(:owner_philodendron)
    item = Stock::Transfer.from_plant!(plant, seller: @seller, location: @greenhouse, member: users(:owner))
    assert_equal [ "specimen", plant, 1 ], [ item.kind, item.plant, item.totals.on_hand ]
    assert_equal "moved_to_stock", plant.reload.status

    owner_ledger = Stock::Ledger.new(item, member: users(:owner))
    hold = owner_ledger.hold!(quantity: 1, location: @greenhouse, held_for: "Buyer", expires_at: 1.day.from_now)
    owner_ledger.fulfil!(hold)
    assert_equal "sold", plant.reload.status
    assert_match "Sold by Fern & Frond (#{item.code})", plant.status_changes.last.reason
  end

  test "a moved specimen goes back to the collection of the member who moved it" do
    plant = plants(:owner_philodendron)
    item = Stock::Transfer.from_plant!(plant, seller: @seller, location: @greenhouse, member: users(:owner))
    assert_raises(Stock::Ledger::Refused) { Stock::Ledger.new(item, member: @member).to_collection! }

    Stock::Ledger.new(item, member: users(:owner)).to_collection!
    assert_equal [ 0, true, "active" ], [ item.reload.totals.on_hand, item.archived?, plant.reload.status ]
  end

  test "a record of several plants must be split before moving to stock" do
    plant = plants(:owner_philodendron)
    plant.update!(quantity: 3)
    assert_raises(Stock::Transfer::Refused) { Stock::Transfer.from_plant!(plant, seller: @seller, location: @greenhouse, member: users(:owner)) }
  end

  test "movements can't be edited" do
    item = batch
    ledger.receive!(quantity: 1, location: @greenhouse)
    assert_raises(ActiveRecord::ReadOnlyRecord) { item.movements.sole.update!(quantity: 9) }
  end

  private
    def batch = @item = @seller.stock_items.create!(kind: "batch", name: "Pothos N'Joy", price: "85")
    def ledger(item = @item) = Stock::Ledger.new(item, member: @member)
end
