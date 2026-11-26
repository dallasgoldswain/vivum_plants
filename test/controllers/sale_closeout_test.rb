require "test_helper"

class SaleCloseoutControllerTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.buyers seller.orders seller.closeout sales.sessions sales.auctions sales.backup_bidder help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @owner = users(:owner)
    @shelf = @seller.stock_locations.create!(name: "Shelf")
    @session = @seller.sale_sessions.create!(name: "Sunday auction", channel: "Aroid Club", created_by: @owner, payment_hours: 24, backup_hours: 12, host_member: users(:packer))
    @session.go_live!(@owner)
    @lots = %w[ MON-1 ALO-1 ].map do |code|
      item = @seller.stock_items.create!(kind: "specimen", name: code, code: code)
      Stock::Ledger.new(item, member: @owner).receive!(quantity: 1, location: @shelf)
      @session.add_lot!(stock_item: item, location: @shelf, quantity: 1).open!(member: @owner)
              .win!(member: @owner, winner: @session.holder("", "Sam", member: @owner), price_cents: 20_000)
    end
  end

  test "an owner links an unresolved name by adding a buyer, creates orders once, splits one and exports the view" do
    sign_in_as @owner
    get sell_sale_session_closeout_path(@session, view: "unresolved")
    assert_response :success
    assert_select "#unresolved", /Sam \(Aroid Club\)/

    buyer_alias = @lots.first.winner_alias
    post sell_buyers_path, params: { alias_id: buyer_alias.id, buyer: { name: "Sam Dube", phone: "082 111 0000" } }, headers: { "HTTP_REFERER" => sell_sale_session_closeout_url(@session, view: "unresolved") }
    assert_redirected_to sell_sale_session_closeout_url(@session, view: "unresolved")
    assert_equal "Sam Dube", buyer_alias.reload.buyer.name

    2.times { post sell_sale_session_closeout_path(@session) }
    order = @session.orders.sole
    assert_equal 2, order.lines.count

    get sell_sale_session_closeout_path(@session)
    assert_select "##{ActionView::RecordIdentifier.dom_id(order)}", /Subtotal R400/

    post sell_order_split_path(order), params: { line_ids: [ order.lines.last.id ], reason: "Ships later" }
    assert_equal 2, @session.orders.count

    get sell_sale_session_closeout_path(@session, view: "awaiting", format: :csv)
    assert_equal 3, response.body.lines.count
    assert_match "Sam Dube,#{order.reference},Lot 1 · MON-1,1,200.0", response.body.lines.second
  end

  test "a host/packer can't open Closeout" do
    sign_in_as users(:packer)
    get sell_sale_session_closeout_path(@session)
    assert_redirected_to root_path
    post sell_sale_session_closeout_path(@session)
    assert_empty @session.orders
  end
end
