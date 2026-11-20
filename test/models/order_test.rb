require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @member = users(:manager)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    @pothos = @seller.stock_items.create!(kind: "batch", name: "Pothos", price_cents: 8500)
    Stock::Ledger.new(@pothos, member: @member).receive!(quantity: 5, location: @greenhouse)
    @monstera = @seller.stock_items.create!(kind: "specimen", name: "Monstera", cultivar: "Thai Constellation", price_cents: 45000)
    Stock::Ledger.new(@monstera, member: @member).receive!(quantity: 1, location: @greenhouse)
  end

  test "orders get O- numbers per seller and snapshot the buyer's name (D179, D186)" do
    first = order
    other = sellers(:aroid_attic).orders.create!(buyer: sellers(:aroid_attic).buyers.create!(name: "Lee", phone: "0839998888"))
    assert_equal [ "O-0001", "O-0002", "O-0001" ], [ first.reference, order.reference, other.reference ]
    assert_equal "Sam Dlamini", first.buyer_name
    assert_not @seller.orders.new(buyer: other.buyer).valid?
  end

  test "a draft leaves stock available; reserving holds it; fulfilling removes it (SE05)" do
    order = order(@pothos => 2)
    assert_equal 5, @pothos.reload.totals.available

    order.reserve!(expires_at: 1.day.from_now, member: @member)
    assert_equal [ 5, 3 ], @pothos.reload.totals.then { [ it.on_hand, it.available ] }
    assert_equal "O-0001 · Sam Dlamini", order.lines.first.stock_hold.held_for

    assert_raises(Order::Reserving::Refused) { order.fulfil!(member: @member) }
    order.fulfil!(member: @member, unpaid_confirmed: true)
    assert order.reload.fulfilled?
    assert_equal [ 3, 0 ], @pothos.reload.totals.then { [ it.on_hand, it.held ] }
    assert_raises(Order::Reserving::Refused) { order.cancel!(reason: "Changed mind", member: @member) }
  end

  test "two orders for the last specimen: one reserves, and nothing is reserved for the other (SE06)" do
    first = order(@monstera => 1)
    second = order(@pothos => 1, @monstera => 1)
    first.reserve!(expires_at: 1.day.from_now, member: @member)

    error = assert_raises(Order::Reserving::Refused) { second.reserve!(expires_at: 1.day.from_now, member: @member) }
    assert_match @monstera.code, error.message
    assert second.reload.draft?
    assert_equal 5, @pothos.reload.totals.available
    assert_equal 1, @monstera.holds.current.count
  end

  test "cancelling releases once; a repeated cancel adds no stock" do
    order = order(@pothos => 2)
    order.reserve!(expires_at: 1.day.from_now, member: @member)
    order.cancel!(reason: "Buyer changed their mind", member: @member)
    order.cancel!(reason: "Again", member: @member)
    assert_equal 5, @pothos.reload.totals.available
    assert_equal 1, @pothos.movements.where(kind: "release").count
    assert_equal "Buyer changed their mind", order.reload.cancel_reason
  end

  test "the agreed price stays when the item's price changes; editing it keeps the old price and a reason (AT21, D183)" do
    order = order(@pothos => 1)
    @pothos.update!(price_cents: 9900)
    line = order.lines.first
    assert_equal 8500, line.reload.unit_price_cents

    assert_raises(Order::Reserving::Refused) { order.change_price!(line, price_cents: 7000, reason: "", member: @member) }
    order.change_price!(line, price_cents: 7000, reason: "Regular buyer", member: @member)
    assert_equal [ 8500, 7000, "Regular buyer" ], line.reload.then { [ it.agreed_price_cents, it.unit_price_cents, it.price_reason ] }
    assert AuditEvent.exists?(action: "order.price_changed", target_id: order.id)
  end

  test "changing a reserved line adjusts its hold; cancelling a line releases it (D183)" do
    order = order(@pothos => 2)
    order.reserve!(expires_at: 1.day.from_now, member: @member)
    line = order.lines.first

    order.change_quantity!(line, quantity: 4, member: @member)
    assert_equal 1, @pothos.reload.totals.available
    assert_raises(Order::Reserving::Refused) { order.change_quantity!(line, quantity: 6, member: @member) }
    assert_equal [ 4, 1 ], [ line.reload.quantity, @pothos.reload.totals.available ]

    added = order.add_line!(item: @monstera, quantity: 1, member: @member)
    assert added.held?
    order.remove_line!(added, reason: "Not ready", member: @member)
    assert added.reload.cancelled?
    assert_equal 1, @monstera.reload.totals.available
    assert_equal 8500 * 4, order.reload.lines_cents
  end

  test "an expired line is held again when the hold is updated (D180)" do
    order = order(@pothos => 2)
    order.reserve!(expires_at: 1.hour.from_now, member: @member)
    travel 2.hours do
      ExpireStockHoldsJob.perform_now
      assert_not order.lines.first.reload.held?
      assert_raises(Order::Reserving::Refused) { order.reload.fulfil!(member: @member, unpaid_confirmed: true) }

      order.reserve!(expires_at: 1.day.from_now, member: @member)
      assert order.lines.first.reload.held?
      assert_equal 3, @pothos.reload.totals.available
    end
  end

  test "shipping copies the address; later edits to the buyer leave the order's copy (D182)" do
    address = @buyer.addresses.create!(recipient: "Sam", street: "1 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    order = order(@pothos => 1)
    order.update!(shipping: "120", discount: "50", discount_reason: "Bundle")
    order.ship_to!(address)
    address.update!(street: "9 Elm Rd")
    assert_equal "1 Oak St", order.reload.shipping_address["street"]
    assert_equal 8500 + 12000 - 5000, order.total_cents
    assert_not @seller.orders.new(buyer: @buyer, discount: "10").valid?
  end

  test "a buyer with an open order can't be deleted; afterwards orders keep their copies (D188)" do
    order = order(@pothos => 1)
    assert_raises(ActiveRecord::RecordNotDestroyed) { @buyer.erase! }

    order.cancel!(reason: "No reply", member: @member)
    @buyer.reload.erase!
    assert_equal "Sam Dlamini", order.reload.buyer_name
    assert_equal Buyer::DELETED_NAME, @buyer.reload.name
  end

  test "addresses unused and unedited for 12 months are redacted (PR07, D188)" do
    old = @buyer.addresses.create!(recipient: "Sam", street: "1 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    used = @buyer.addresses.create!(recipient: "Sam", street: "2 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    old.update_columns(updated_at: 13.months.ago)
    used.update_columns(updated_at: 13.months.ago, last_used_at: 1.month.ago)
    PrivacyHousekeepingJob.perform_now
    assert_equal [ used ], @buyer.addresses.reload.to_a
  end

  private
    def order(lines = {})
      @seller.orders.create!(buyer: @buyer).tap do |order|
        lines.each { |item, quantity| order.add_line!(item: item, quantity: quantity, member: @member) }
      end
    end
end
