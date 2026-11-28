require "test_helper"
require "vips"

class BusinessProfileTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.profile seller.logo seller.social_links seller.stock seller.reservations seller.buyers seller.orders
              payments.manual seller.receipts seller.listings seller.sale_cards help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    sign_in_as users(:owner)
  end

  test "an owner uploads a wide logo, which is kept whole and audited (D251, D254)" do
    get edit_sell_business_details_path
    assert_select "h2", "Business profile"
    assert_select "input[type=file][name='seller[logo]']"

    patch sell_business_details_path, params: { seller: { logo: logo_upload(800, 200) } }
    assert_redirected_to edit_sell_business_details_path
    image = Vips::Image.new_from_buffer(@seller.reload.logo.download, "")
    assert_equal [ 800, 200 ], [ image.width, image.height ]
    assert_equal "image/png", @seller.logo.content_type
    assert AuditEvent.exists?(action: "seller.logo_changed")
  end

  test "a logo over 5 MB or not an image is refused" do
    patch sell_business_details_path, params: { seller: { logo: fixture_file_upload("not_a_photo.txt", "image/png") } }
    assert_response :unprocessable_entity
    assert_match "Choose a PNG, JPEG or WebP logo.", response.body

    big = Tempfile.new([ "big", ".png" ])
    big.binmode
    big.write(Vips::Image.gaussnoise(1500, 1500).bandjoin([ Vips::Image.gaussnoise(1500, 1500), Vips::Image.gaussnoise(1500, 1500) ]).cast(:uchar).write_to_buffer(".png", compression: 0))
    big.rewind
    assert_operator big.size, :>, 5.megabytes
    patch sell_business_details_path, params: { seller: { logo: Rack::Test::UploadedFile.new(big.path, "image/png") } }
    assert_match "That logo is over 5 MB.", response.body
    assert_response :unprocessable_entity
    assert_not @seller.reload.logo.attached?
  end

  test "links are saved clean and audited; a link for the wrong site is refused (D256)" do
    patch sell_business_details_path, params: { seller: { instagram_url: "https://www.facebook.com/x" } }
    assert_response :unprocessable_entity
    assert_match "must be an Instagram @handle", response.body

    patch sell_business_details_path, params: { seller: { instagram_url: "@plantshop", whatsapp_number: "082 123 4567", show_whatsapp: "0", card_link: "instagram" } }
    assert_redirected_to edit_sell_business_details_path
    assert_equal [ "https://www.instagram.com/plantshop", "+27821234567", false ], @seller.reload.values_at(:instagram_url, :whatsapp_number, :show_whatsapp)
    assert AuditEvent.exists?(action: "seller.links_changed")
  end

  test "managers and host/packers can't change the logo or links" do
    [ users(:manager), users(:packer) ].each do |user|
      sign_in_as user
      patch sell_business_details_path, params: { seller: { instagram_url: "@other", logo: logo_upload(100, 100) } }
      assert_redirected_to root_path
    end
    assert_nil @seller.reload.instagram_url
    assert_not @seller.logo.attached?
  end

  test "a receipt keeps the logo and links it was issued with (D255)" do
    @seller.update!(instagram_url: "@plantshop", whatsapp_number: "0821234567", show_whatsapp: false)
    patch sell_business_details_path, params: { seller: { logo: logo_upload(400, 100) } }
    first_logo = @seller.reload.logo.blob
    order = paid_order

    details = order.receipt.details["seller"]
    assert_equal first_logo.id, details["logo_blob_id"]
    assert_equal [ { "name" => "Instagram", "text" => "@plantshop" } ], details["links"]

    patch sell_business_details_path, params: { seller: { logo: logo_upload(200, 200) } }
    perform_enqueued_jobs
    assert_not_equal first_logo.id, @seller.reload.logo.blob.id
    assert ActiveStorage::Blob.exists?(first_logo.id)

    get sell_order_document_path(order, order.receipt, format: :pdf)
    assert_equal "application/pdf", response.media_type
    assert_match "/Subtype /Image", response.body
  end

  test "a sale card shows the logo and card link, and goes stale when they change (D253, D255)" do
    @seller.update!(instagram_url: "@plantshop", card_link: "instagram")
    item = @seller.stock_items.create!(kind: "batch", name: "Pothos", price: "450")
    Stock::Ledger.new(item, member: users(:owner)).receive!(quantity: 1, location: @seller.stock_locations.create!(name: "Greenhouse"))
    listing = @seller.listings.create!(stock_item: item, title: "Pothos", price: "450", state: "active")
    card = SaleCard.render!(listing, format: "square", file_type: "png", created_by: users(:owner))
    assert_equal "Fern & Frond · @plantshop", card.business_label
    assert_nil card.stale_reason

    patch sell_business_details_path, params: { seller: { logo: logo_upload(300, 100) } }
    assert_equal "Shows older business details.", card.reload.stale_reason

    fresh = SaleCard.render!(listing.reload, format: "square", file_type: "png", created_by: users(:owner))
    assert_equal @seller.reload.logo.blob.id, fresh.logo_blob_id
    assert_nil fresh.stale_reason
  end

  test "a seller with no paid plan can use the logo and links (BR01)" do
    @seller.update!(plan: plans(:starter), audit_reason: "Starter for the test")
    assert_not @seller.entitled_to?("paid_branding")
    patch sell_business_details_path, params: { seller: { logo: logo_upload(100, 100), youtube_url: "@fernfrond" } }
    assert @seller.reload.logo_shown?
    assert_equal [ "youtube" ], @seller.shown_links.map(&:key)
  end

  private
    def logo_upload(width, height)
      file = Tempfile.new([ "logo", ".png" ])
      file.binmode
      file.write(Vips::Image.black(width, height, bands: 3).add([ 30, 90, 60 ]).cast(:uchar).write_to_buffer(".png"))
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "image/png")
    end

    def paid_order
      buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0831234567")
      item = @seller.stock_items.create!(kind: "batch", name: "Monstera", price_cents: 20000)
      Stock::Ledger.new(item, member: users(:owner)).receive!(quantity: 1, location: @seller.stock_locations.create!(name: "Shed"))
      order = @seller.orders.create!(buyer: buyer)
      order.add_line!(item: item, quantity: 1, member: users(:owner))
      order.record_payment!(amount_cents: 20000, method: "eft", paid_on: Date.current, member: users(:owner))
      order.reload
    end
end
