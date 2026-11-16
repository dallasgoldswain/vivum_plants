require "test_helper"

class BuyersTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.buyers buyer.phone_verification privacy.buyer_dsr help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
  end

  test "buyers are hidden while the flag is off" do
    Flipper.disable("seller.buyers")
    sign_in_as users(:owner)
    get sell_buyers_path
    assert_response :not_found
  end

  test "an owner adds a buyer, and a clashing number names the existing buyer (D171, D178)" do
    sign_in_as users(:owner)
    post sell_buyers_path, params: { buyer: { name: "Sam Dlamini", phone: "082 123 4567", contact_preference: "whatsapp" } }
    buyer = @seller.buyers.sole
    assert_redirected_to sell_buyer_path(buyer)
    assert_equal "+27821234567", buyer.phone

    post sell_buyers_path, params: { buyer: { name: "Sam D", phone: "+27821234567" } }
    assert_response :unprocessable_entity
    assert_match "Phone belongs to Sam Dlamini", response.body

    get sell_buyers_path, params: { q: "0821234567" }
    assert_select "#buyers li", 1
  end

  test "another seller's buyer is not found" do
    other = sellers(:aroid_attic).buyers.create!(name: "Lee", phone: "0839998888")
    sign_in_as users(:owner)
    get sell_buyer_path(other)
    assert_response :not_found
    get sell_buyers_path, params: { q: "0839998888" }
    assert_select "#buyers li", 0
  end

  test "a host/packer sees names and aliases and adds aliases, never phones or addresses (D176)" do
    buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    buyer.addresses.create!(recipient: "Sam", street: "1 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    sign_in_as users(:packer)
    get sell_buyers_path
    assert_response :success
    assert_match "Sam Dlamini", response.body
    assert_no_match "82 123", response.body

    get sell_buyer_path(buyer)
    assert_redirected_to root_path
    get sell_buyers_path(format: :csv)
    assert_response :forbidden

    post sell_buyer_aliases_path, params: { buyer_alias: { name: "Sam 🌿", group_name: "Sunday auction" } }
    assert_equal users(:packer), @seller.buyer_aliases.sole.created_by
    patch sell_buyer_alias_path(@seller.buyer_aliases.sole), params: { buyer_id: buyer.id }
    assert_nil @seller.buyer_aliases.sole.buyer
  end

  test "a manager links an alias and holds stock for it (D172)" do
    buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    buyer_alias = @seller.buyer_aliases.create!(name: "Sam 🌿")
    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    post sell_buyer_alias_links_path(buyer), params: { alias_id: buyer_alias.id }
    assert_equal buyer, buyer_alias.reload.buyer

    location = @seller.stock_locations.create!(name: "Greenhouse")
    item = @seller.stock_items.create!(kind: "batch", name: "Pothos")
    Stock::Ledger.new(item, member: users(:owner)).receive!(quantity: 2, location: location)
    post sell_stock_item_holds_path(item), params: { holder: "buyer:#{buyer.id}", quantity: "1", location_id: location.id, expires_at: 2.days.from_now.strftime("%Y-%m-%dT%H:%M") }
    assert_equal [ buyer, "Sam Dlamini" ], item.holds.sole.then { [ it.buyer, it.held_for ] }

    get sell_buyer_path(buyer)
    assert_select "#holds li", 1
  end

  test "the verification link opens WhatsApp, and the buyer confirms once and sets consents (BY03, D173, D174)" do
    buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    sign_in_as users(:owner)
    post sell_buyer_verification_path(buyer)
    assert_match %r{\Ahttps://wa\.me/27821234567\?text=}, response.location
    token = CGI.unescape(response.location)[%r{/v/([\w-]+)}, 1]
    sign_out

    get buyer_verification_path(token)
    assert_response :success
    assert_match "Fern &amp; Frond", response.body
    assert_match "+27 82 *** **67", response.body
    assert_no_match "Dlamini", response.body

    post buyer_verification_path(token), params: { consents: { whatsapp_messages: "1" } }
    follow_redirect!
    assert_match "your number is confirmed", response.body
    buyer.reload
    assert buyer.verified?
    assert buyer.consent?(:whatsapp_messages)
    assert_not buyer.consent?(:marketing)

    post buyer_verification_path(token)
    assert_response :gone
    assert_match "no longer works", response.body
  end

  test "an unknown verification token is not found" do
    get buyer_verification_path("nope")
    assert_response :not_found
  end

  test "the seller records and withdraws consent (D174)" do
    buyer = @seller.buyers.create!(name: "Sam", phone: "0821234567")
    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    post sell_buyer_consents_path(buyer), params: { purpose: "marketing", granted: "1", method: "Said yes in chat", given_on: Date.current.iso8601 }
    assert buyer.reload.consent?(:marketing)
    post sell_buyer_consents_path(buyer), params: { purpose: "marketing", granted: "0" }
    assert_not buyer.reload.consent?(:marketing)
  end

  test "an owner downloads and deletes a buyer's data; a manager can't (D177)" do
    buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    delete sell_buyer_path(buyer)
    assert_redirected_to root_path
    assert_not buyer.reload.deleted?
    sign_out

    sign_in_as users(:owner)
    get sell_buyer_export_path(buyer)
    assert_equal "Sam Dlamini", response.parsed_body.dig("buyer", "name")

    delete sell_buyer_path(buyer)
    assert buyer.reload.deleted?
    assert_equal %w[ buyer.exported buyer.deleted ], AuditEvent.where(target_type: "Buyer", target_id: buyer.id).order(:id).pluck(:action)
    get sell_buyer_path(buyer)
    assert_response :not_found
  end

  test "merging from the buyer page (D178)" do
    keep = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    other = @seller.buyers.create!(name: "Sammy", phone: "0831112222")
    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    post sell_buyer_merge_path(keep), params: { other_buyer_id: other.id }
    assert_match "Sammy merged", flash[:notice]
    assert_not Buyer.exists?(other.id)
  end

  test "the CSV export lists buyers for owners and managers" do
    @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    sign_in_as users(:owner)
    get sell_buyers_path(format: :csv)
    assert_match "Sam Dlamini,+27821234567", response.body
  end
end
