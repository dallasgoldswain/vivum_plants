require "test_helper"

class StockTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations collection.plants help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @shelf = @seller.stock_locations.create!(name: "Shop shelf")
  end

  test "stock is hidden while the flag is off" do
    Flipper.disable("seller.stock")
    sign_in_as users(:owner)
    get sell_stock_items_path
    assert_response :not_found
  end

  test "an owner adds a batch with its first stock, and sees price and availability (SE01)" do
    sign_in_as users(:owner)
    post sell_stock_items_path, params: { stock_item: { kind: "batch", name: "Pothos N'Joy", size: "12 cm pot", price: "85", cost: "30" }, receive_quantity: "10", receive_location_id: @greenhouse.id }
    item = @seller.stock_items.sole
    assert_redirected_to sell_stock_item_path(item)
    assert_equal [ "S-0001", 8500, 3000, 10 ], [ item.code, item.price_cents, item.cost_cents, item.totals.on_hand ]

    follow_redirect!
    assert_select "#stock h2", "10 available"
    assert_match "R85 each", response.body
    assert_match "cost R30", response.body
  end

  test "a packer moves stock and marks it unavailable but never sees prices or receives (D161)" do
    item = stocked_item(5)
    sign_in_as users(:packer)
    get sell_stock_item_path(item)
    assert_response :success
    assert_no_match "R85", response.body
    assert_select "summary", text: "Receive", count: 0

    post sell_stock_item_movements_path(item), params: { kind: "move", quantity: "2", location_id: @greenhouse.id, to_location_id: @shelf.id }
    post sell_stock_item_movements_path(item), params: { kind: "mark_unavailable", quantity: "1", location_id: @shelf.id, reason: "Damaged" }
    assert_equal [ 4, 1 ], item.reload.totals.then { [ it.available, it.unavailable ] }
    assert_equal users(:packer), item.movements.order(:id).last.member

    post sell_stock_item_movements_path(item), params: { kind: "receipt", quantity: "3", location_id: @greenhouse.id }
    assert_redirected_to root_path
    assert_equal 5, item.reload.totals.on_hand
    get sell_stock_items_path
    assert_no_match "R85", response.body
  end

  test "holds: create, refuse more than available, fulfil" do
    item = stocked_item(3)
    sign_in_as users(:owner)
    post sell_stock_item_holds_path(item), params: { held_for: "Thandi", quantity: "2", location_id: @greenhouse.id, expires_at: 2.days.from_now.strftime("%Y-%m-%dT%H:%M") }
    post sell_stock_item_holds_path(item), params: { held_for: "Lee", quantity: "2", location_id: @greenhouse.id, expires_at: 2.days.from_now.strftime("%Y-%m-%dT%H:%M") }
    assert_match "Only 1 available", flash[:alert]

    hold = item.holds.sole
    post fulfil_sell_stock_item_hold_path(item, hold)
    assert_equal [ 1, 1 ], item.reload.totals.then { [ it.on_hand, it.available ] }
  end

  test "a hold without an end time is refused (D14)" do
    item = stocked_item(1)
    sign_in_as users(:owner)
    post sell_stock_item_holds_path(item), params: { held_for: "Thandi", quantity: "1", location_id: @greenhouse.id, expires_at: "" }
    assert_match "Choose when the hold ends", flash[:alert]
    assert_empty item.holds
  end

  test "a count can't go below what's held" do
    item = stocked_item(4)
    Stock::Ledger.new(item, member: users(:owner)).hold!(quantity: 3, location: @greenhouse, held_for: "A", expires_at: 1.day.from_now)
    sign_in_as users(:owner)
    post sell_stock_item_movements_path(item), params: { kind: "count", counted: "2", location_id: @greenhouse.id }
    assert_match "held at Greenhouse", flash[:alert]
    assert_equal 4, item.reload.totals.saleable
  end

  test "moving a plant from your collection to stock (SE04, D162)" do
    plant = plants(:owner_philodendron)
    sign_in_as users(:owner)
    get plant_path(plant)
    assert_select "a", "Move to stock…"
    post plant_stock_transfer_path(plant), params: { location_id: @greenhouse.id, price: "450" }
    item = @seller.stock_items.sole
    assert_redirected_to sell_stock_item_path(item)
    assert_equal [ plant, 45000 ], [ item.plant, item.price_cents ]
    get plant_path(plant)
    assert_select ".vv-timeline li", /Moved to Fern &amp; Frond stock|Moved to Fern & Frond stock/
  end

  test "a packer can't move a plant to stock" do
    sign_in_as users(:packer)
    plant = users(:packer).plants.create!(display_name: "Fern", growing_context: "indoor")
    post plant_stock_transfer_path(plant), params: { location_id: @greenhouse.id }
    assert_response :not_found
  end

  test "another seller's stock isn't found" do
    other = sellers(:aroid_attic).stock_items.create!(kind: "batch", name: "Theirs")
    sign_in_as users(:owner)
    get sell_stock_item_path(other)
    assert_response :not_found
    post sell_stock_item_movements_path(other), params: { kind: "loss", quantity: "1", location_id: @greenhouse.id }
    assert_response :not_found
  end

  test "owners download stock and its history as CSV; packers can't" do
    stocked_item(2)
    sign_in_as users(:owner)
    get sell_stock_export_path(format: :csv)
    assert_match "S-0001,batch,Pothos", response.body
    get sell_stock_export_path(format: :csv, kind: "movements")
    assert_match "receipt,2", response.body

    sign_in_as users(:packer)
    get sell_stock_export_path(format: :csv)
    assert_response :forbidden
  end

  test "an empty location can be archived; one with stock can't" do
    stocked_item(1)
    sign_in_as users(:owner)
    patch sell_stock_location_path(@greenhouse), params: { archive: "1" }
    assert_not @greenhouse.reload.archived?
    patch sell_stock_location_path(@shelf), params: { archive: "1" }
    assert @shelf.reload.archived?
  end

  private
    def stocked_item(quantity)
      @seller.stock_items.create!(kind: "batch", name: "Pothos N'Joy", price: "85").tap do |item|
        Stock::Ledger.new(item, member: users(:owner)).receive!(quantity: quantity, location: @greenhouse)
      end
    end
end
