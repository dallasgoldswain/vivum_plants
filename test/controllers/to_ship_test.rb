require "test_helper"

class ToShipControllerTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.buyers seller.orders seller.receipts seller.packing shipping.pickup shipping.manual help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @owner = users(:owner)
    shelf = @seller.stock_locations.create!(name: "Shelf")
    buyer = @seller.buyers.create!(name: "Sam Dube", phone: "0821110000")
    address = buyer.addresses.create!(label: "Home", recipient: "Sam Dube", street: "1 Fern Road", suburb: "Observatory", city: "Cape Town", province: "Western Cape", postal_code: "7925")
    item = @seller.stock_items.create!(kind: "batch", name: "Pothos", code: "POT-1", price_cents: 8_500)
    Stock::Ledger.new(item, member: @owner).receive!(quantity: 10, location: shelf)

    @shipping = paid_order(buyer, item) { it.ship_to!(address) }
    @pickup = paid_order(buyer, item)
    @unpaid = @seller.orders.create!(buyer: buyer).tap { it.add_line!(item: item, quantity: 1, member: @owner) }
  end

  test "an owner sees paid orders only, prints slips without prices, packs and ships one" do
    sign_in_as @owner
    get sell_to_ship_path
    assert_response :success
    assert_select "##{dom_id(@shipping)}", /1 Fern Road/
    assert_select "##{dom_id(@pickup)}", /Pickup/
    assert_select "##{dom_id(@unpaid)}", count: 0

    get slips_sell_to_ship_path
    assert_response :success
    assert_select "article", count: 2
    assert_select "##{dom_id(@shipping, :slip)}", /POT-1/
    assert_select "##{dom_id(@pickup, :slip)}", /Pickup/
    assert_no_match(/R\d/, response.body)

    get sell_order_slip_path(@shipping)
    assert_select "article", count: 1

    post sell_order_packing_path(@shipping), headers: { "HTTP_REFERER" => sell_to_ship_url }
    assert_redirected_to sell_to_ship_url
    assert @shipping.reload.packed?

    post sell_order_fulfilment_path(@shipping), params: { courier: "PUDO", tracking_reference: "TRK1" }, headers: { "HTTP_REFERER" => sell_to_ship_url }
    assert_equal [ "fulfilled", "TRK1" ], [ @shipping.reload.state, @shipping.tracking_reference ]
    get sell_to_ship_path
    assert_select "##{dom_id(@shipping)}", count: 0
  end

  test "a host/packer can't open To ship or slips" do
    sign_in_as users(:packer)
    get sell_to_ship_path
    assert_redirected_to root_path
    get sell_order_slip_path(@shipping)
    assert_redirected_to root_path
  end

  private
    def dom_id(...) = ActionView::RecordIdentifier.dom_id(...)

    def paid_order(buyer, item)
      order = @seller.orders.create!(buyer: buyer)
      yield order if block_given?
      order.add_line!(item: item, quantity: 2, member: @owner)
      order.reserve!(expires_at: 1.day.from_now, member: @owner)
      order.record_payment!(amount_cents: order.total_cents, method: "eft", paid_on: Date.current, member: @owner)
      order.reload
    end
end
