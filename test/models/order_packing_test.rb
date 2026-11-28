require "test_helper"

class OrderPackingTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @member = users(:owner)
    @shelf = @seller.stock_locations.create!(name: "Shelf")
    @buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    @pothos = @seller.stock_items.create!(kind: "batch", name: "Pothos", code: "POT-1", price_cents: 8_500)
    Stock::Ledger.new(@pothos, member: @member).receive!(quantity: 10, location: @shelf)
  end

  test "To ship holds only reserved orders paid in full, oldest payment first (D240)" do
    later = order(paid_on: Date.current)
    earlier = order(paid_on: 2.days.ago.to_date)
    part = order(paid_cents: 1_000)
    order(paid_cents: 0)
    draft = @seller.orders.create!(buyer: @buyer)

    assert_equal [ earlier, later ], @seller.orders.to_ship.to_a
    assert_not part.to_ship?
    assert_not draft.to_ship?
  end

  test "packed is a tick that undoes until shipping, and each change is audited (D241)" do
    order = order()
    assert_difference -> { AuditEvent.where(action: "order.packed").count }, 1 do
      2.times { order.pack!(member: @member) }
    end
    assert order.reload.packed?
    assert_equal @member, order.packed_by

    order.unpack!(member: @member)
    assert_not order.reload.packed?
    assert AuditEvent.exists?(action: "order.unpacked", target_id: order.id)

    order.pack!(member: @member)
    order.fulfil!(member: @member)
    assert_raises(Order::Reserving::Refused) { order.unpack!(member: @member) }
    assert_raises(Order::Reserving::Refused) { order(paid_cents: 0).pack!(member: @member) }
  end

  test "shipping removes the stock once" do
    order = order()
    2.times { order.fulfil!(member: @member, courier: "PUDO", tracking_reference: "TRK1") }
    assert_equal 8, @pothos.reload.totals.on_hand
    assert_equal [ "PUDO", "TRK1" ], [ order.courier, order.tracking_reference ]
  end

  private
    def order(paid_cents: nil, paid_on: Date.current)
      order = @seller.orders.create!(buyer: @buyer)
      order.add_line!(item: @pothos, quantity: 2, member: @member)
      order.reserve!(expires_at: 1.day.from_now, member: @member)
      amount = paid_cents || order.total_cents
      order.record_payment!(amount_cents: amount, method: "eft", paid_on: paid_on, member: @member) if amount.positive?
      order.reload
    end
end
