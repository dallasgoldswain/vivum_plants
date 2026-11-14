require "test_helper"

class ListingsTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.listings seller.sale_cards whatsapp.share help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @item = @seller.stock_items.create!(kind: "batch", name: "Pothos N'Joy", price: "450", size: "12 cm pot")
    Stock::Ledger.new(@item, member: users(:owner)).receive!(quantity: 3, location: @greenhouse)
    sign_in_as users(:owner)
  end

  test "listing an item from its page" do
    get sell_stock_item_path(@item)
    assert_select "a", "List it"
    post sell_listings_path, params: { stock_item_id: @item.id, activate: "1", listing: { title: "Pothos N'Joy", price: "450", details: "Courier nationwide" } }
    listing = @seller.listings.sole
    assert_redirected_to sell_listing_path(listing)
    assert listing.active?
    follow_redirect!
    assert_match(/3\s+available/, response.body)
  end

  test "a card shows the listing's price, is stored with it, and is flagged when the price changes (SE07, D167)" do
    upload_photo
    listing = Listing.from_item(@item.reload).tap(&:save!).tap(&:activate!)
    post sell_listing_sale_cards_path(listing), params: { format_name: "status", file_type: "png" }
    card = listing.sale_cards.sole
    assert_equal [ 45000, "Pothos N'Joy", @item.cover_photo_id ], [ card.price_cents, card.title, card.photo_id ]
    image = Vips::Image.new_from_buffer(card.image.download, "")
    assert_equal [ 1080, 1920 ], [ image.width, image.height ]

    get sell_listing_path(listing)
    assert_select "#card-#{card.id} .alert", 0
    assert_select "#card-#{card.id} a[href^='https://wa.me/?text=']"

    listing.update!(price: "500")
    get sell_listing_path(listing)
    assert_select "#card-#{card.id} .alert", /Shows R450; the price is now R500/
  end

  test "making a card or sharing never holds stock or creates an order (SE08)" do
    listing = Listing.from_item(@item).tap(&:save!).tap(&:activate!)
    assert_no_difference -> { StockHold.count } do
      post sell_listing_sale_cards_path(listing), params: { format_name: "square" }
      get sell_listing_sale_card_path(listing, listing.sale_cards.sole, download: 1)
    end
    assert_equal "attachment", response.headers["Content-Disposition"].split(";").first
  end

  test "no card for a sold-out or paused listing" do
    listing = Listing.from_item(@item).tap(&:save!)
    post sell_listing_sale_cards_path(listing)
    assert_empty listing.sale_cards
  end

  test "pausing and ending never change stock" do
    listing = Listing.from_item(@item).tap(&:save!).tap(&:activate!)
    patch sell_listing_state_path(listing), params: { state: "paused" }
    patch sell_listing_state_path(listing), params: { state: "ended" }
    assert listing.reload.ended?
    assert_equal 3, @item.totals.available
  end

  test "host/packers can't open listings" do
    sign_in_as users(:packer)
    get sell_listings_path
    assert_redirected_to root_path
  end

  test "another seller's listing isn't found" do
    other_item = sellers(:aroid_attic).stock_items.create!(kind: "batch", name: "Theirs", price: "10")
    other = Listing.from_item(other_item).tap(&:save!)
    get sell_listing_path(other)
    assert_response :not_found
  end

  test "settings set the default collection and delivery details" do
    patch sell_stock_settings_path, params: { listing_details: "Collect in Durban North" }
    get new_sell_listing_path(stock_item_id: @item.id)
    assert_select "textarea[name='listing[details]']", "Collect in Durban North"
  end

  private
    def upload_photo
      post sell_stock_item_photos_path(@item), params: { photo: { images: [ fixture_file_upload("leaf.jpg", "image/jpeg") ] } }
    end
end
