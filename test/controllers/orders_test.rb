require "test_helper"

class OrdersTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.buyers seller.orders privacy.buyer_dsr help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    @address = @buyer.addresses.create!(recipient: "Sam", street: "1 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    @pothos = @seller.stock_items.create!(kind: "batch", name: "Pothos", price_cents: 8500)
    Stock::Ledger.new(@pothos, member: users(:owner)).receive!(quantity: 5, location: @greenhouse)
  end

  test "orders are hidden while the flag is off" do
    Flipper.disable("seller.orders")
    sign_in_as users(:owner)
    get sell_orders_path
    assert_response :not_found
  end

  test "an owner starts an order, adds a plant, ships it, reserves and marks it shipped" do
    sign_in_as users(:owner)
    post sell_orders_path, params: { order: { buyer_id: @buyer.id, source: "chat" } }
    order = @seller.orders.sole
    assert_redirected_to sell_order_path(order)

    post sell_order_lines_path(order), params: { stock_item_id: @pothos.id, quantity: 2 }
    patch sell_order_path(order), params: { order: { delivery_method: "shipping", address_id: @address.id, shipping: "120" } }
    assert_equal [ "1 Oak St", 12000 ], order.reload.then { [ it.shipping_address["street"], it.shipping_cents ] }

    post sell_order_reservation_path(order), params: { expires_at: 2.days.from_now.strftime("%Y-%m-%dT%H:%M") }
    assert order.reload.reserved?
    assert_equal 3, @pothos.reload.totals.available

    get sell_order_path(order)
    assert_select "#order_total", "R290"
    get sell_stock_item_path(@pothos)
    assert_select "#holds a", text: "O-0001"
    assert_select "#holds button", text: "Release", count: 0

    post sell_order_fulfilment_path(order), params: { courier: "Pargo" }
    assert order.reload.reserved?
    assert_match "hasn't been paid", flash[:alert]

    post sell_order_fulfilment_path(order), params: { courier: "Pargo", tracking_reference: "PG123", unpaid_confirmed: "1" }
    assert order.reload.fulfilled?
    assert_equal [ 3, "PG123" ], [ @pothos.reload.totals.on_hand, order.tracking_reference ]
  end

  test "an order's hold can't be released from the stock page" do
    order = @seller.orders.create!(buyer: @buyer)
    order.add_line!(item: @pothos, quantity: 1, member: users(:owner))
    order.reserve!(expires_at: 1.day.from_now, member: users(:owner))
    sign_in_as users(:owner)
    post release_sell_stock_item_hold_path(@pothos, order.lines.first.stock_hold)
    assert_match "change it on the order", flash[:alert]
    assert order.lines.first.reload.held?
  end

  test "cancelling twice releases once" do
    order = @seller.orders.create!(buyer: @buyer)
    order.add_line!(item: @pothos, quantity: 2, member: users(:owner))
    order.reserve!(expires_at: 1.day.from_now, member: users(:owner))
    sign_in_as users(:owner)
    2.times { post sell_order_cancellation_path(order), params: { reason: "No reply" } }
    assert order.reload.cancelled?
    assert_equal 5, @pothos.reload.totals.available
  end

  test "a manager works with orders; a host/packer can't open them (D185)" do
    order = @seller.orders.create!(buyer: @buyer)
    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    get sell_orders_path
    assert_select "#orders li", 1

    sign_in_as users(:packer)
    get sell_orders_path
    assert_redirected_to root_path
    get sell_order_path(order)
    assert_redirected_to root_path
    get sell_orders_path(format: :csv)
    assert_response :forbidden
  end

  test "another seller's order is not found, and search finds by number, buyer and item" do
    other = sellers(:aroid_attic)
    foreign = other.orders.create!(buyer: other.buyers.create!(name: "Lee", phone: "0839998888"))
    order = @seller.orders.create!(buyer: @buyer)
    order.add_line!(item: @pothos, quantity: 1, member: users(:owner))
    sign_in_as users(:owner)
    get sell_order_path(foreign)
    assert_response :not_found

    %w[ O-0001 sam pothos S-0001 ].each do |query|
      get sell_orders_path, params: { q: query }
      assert_select "#orders li", 1, query
    end
  end

  test "orders and lines download as CSV, and in the buyer's data" do
    order = @seller.orders.create!(buyer: @buyer)
    order.add_line!(item: @pothos, quantity: 2, member: users(:owner))
    sign_in_as users(:owner)
    get sell_orders_path(format: :csv)
    assert_match "O-0001,Sam Dlamini,chat,draft,unpaid,pickup,,170.0", response.body
    get sell_orders_path(format: :csv, kind: "lines")
    assert_match "O-0001,S-0001,Pothos,2,85.0,85.0", response.body
    get sell_buyer_export_path(@buyer)
    assert_equal "O-0001", response.parsed_body["orders"].sole["number"]
  end

  test "deleting a buyer with an open order is refused (D188)" do
    @seller.orders.create!(buyer: @buyer)
    sign_in_as users(:owner)
    delete sell_buyer_path(@buyer)
    assert_redirected_to sell_buyer_path(@buyer)
    assert_match "open orders", flash[:alert]
    assert_not @buyer.reload.deleted?
  end
end
