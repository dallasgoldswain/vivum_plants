require "test_helper"

class SaleSessionsTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.buyers sales.sessions sales.auctions sales.backup_bidder sales.quick_claim sales.waitlist help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @shelf = @seller.stock_locations.create!(name: "Shelf")
    @monstera = @seller.stock_items.create!(kind: "specimen", name: "Monstera", code: "MON-1", price_cents: 50_000)
    @pothos = @seller.stock_items.create!(kind: "batch", name: "Pothos", code: "POT-1", price_cents: 8_500)
    Stock::Ledger.new(@monstera, member: users(:owner)).receive!(quantity: 1, location: @shelf)
    Stock::Ledger.new(@pothos, member: users(:owner)).receive!(quantity: 1, location: @shelf)
  end

  test "an owner sets up a session, goes live, and the host captures a win and claims" do
    sign_in_as users(:owner)
    get new_sell_sale_session_path
    assert_response :success
    post sell_sale_sessions_path, params: { sale_session: { name: "Sunday auction", channel: "Aroid Club", host_member_id: users(:packer).id } }
    sale_session = @seller.sale_sessions.sole

    patch sell_sale_session_status_path(sale_session), params: { status: "live" }
    assert_match "Set the payment deadline", flash[:alert]
    patch sell_sale_session_path(sale_session), params: { sale_session: { payment_hours: 24, backup_hours: 12 } }
    post sell_sale_session_lots_path(sale_session), params: { stock_item_id: @monstera.id, stock_location_id: @shelf.id, quantity: 1 }
    post sell_sale_session_claim_items_path(sale_session), params: { stock_item_id: @pothos.id, stock_location_id: @shelf.id }
    patch sell_sale_session_status_path(sale_session), params: { status: "live" }
    assert sale_session.reload.live?
    assert_equal 8_500, sale_session.claim_items.sole.price_cents

    sign_in_as users(:packer)
    get sell_sale_sessions_path
    assert_select "#sessions a[href=?]", sell_sale_session_host_path(sale_session)
    get sell_sale_session_path(sale_session)
    assert_redirected_to root_path

    lot = sale_session.lots.sole
    post open_sell_sale_session_lot_path(sale_session, lot)
    get sell_sale_session_host_path(sale_session)
    assert_select "#open_lot h2", /Lot 1 · Monstera/
    assert_no_match "R500", response.body, "hosts don't see the item price"

    post win_sell_sale_session_lot_path(sale_session, lot), params: { winner_name: "Sam", price: "450", backup_name: "Lee", backup_bid: "400" }
    assert lot.reload.won?
    assert_equal [ "Sam (Aroid Club)", 45_000, "Lee (Aroid Club)" ], [ lot.winner_name, lot.price_cents, lot.backup_name ]

    claim_item = sale_session.claim_items.sole
    post sell_sale_session_claims_path(sale_session), params: { claim_item_id: claim_item.id, claimer_name: "Ana", quantity: 1, message_reference: "10:02" }
    post sell_sale_session_claims_path(sale_session), params: { claim_item_id: claim_item.id, claimer_name: "Ben", quantity: 1 }
    assert_equal %w[ held waitlisted ], claim_item.claims.map(&:state)
    assert_match "#1 on the waitlist", flash[:notice]

    post return_stock_sell_sale_session_lot_path(sale_session, lot)
    assert_redirected_to root_path
    assert lot.reload.won?, "only owners and managers settle results"
  end

  test "a host/packer who isn't the host can't open Host View" do
    sale_session = @seller.sale_sessions.create!(name: "Claims", payment_hours: 2, backup_hours: 2, host_member: users(:manager))
    sign_in_as users(:packer)
    get sell_sale_session_host_path(sale_session)
    assert_response :not_found
  end

  test "results download as CSV for owners" do
    sale_session = @seller.sale_sessions.create!(name: "Sunday", payment_hours: 2, backup_hours: 2, status: "live")
    lot = sale_session.add_lot!(stock_item: @monstera, location: @shelf, quantity: 1)
    lot.open!(member: users(:owner))
    lot.win!(member: users(:owner), winner: sale_session.holder("", "Sam", member: users(:owner)), price_cents: 45_000)
    sign_in_as users(:owner)
    get sell_sale_sessions_path(format: :csv)
    assert_match "Sunday,lot,1,MON-1,1,won,Sam,450.0", response.body
  end
end
