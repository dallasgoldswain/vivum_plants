require "test_helper"

class SellerIdentityTest < ActiveSupport::TestCase
  setup do
    %w[ seller.workspace seller.profile seller.logo seller.social_links ].each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
  end

  test "a link takes an @handle or a link for its own site and is stored clean (D256)" do
    @seller.update!(instagram_url: "@plantshop", facebook_url: "https://m.facebook.com/fernfrond/?ref=bookmarks", youtube_url: "youtube.com/@fernfrond", whatsapp_number: "082 123 4567")
    assert_equal "https://www.instagram.com/plantshop", @seller.instagram_url
    assert_equal "https://www.facebook.com/fernfrond", @seller.facebook_url
    assert_equal "https://www.youtube.com/@fernfrond", @seller.youtube_url
    assert_equal "+27821234567", @seller.whatsapp_number
    assert_equal [ "@plantshop", "facebook.com/fernfrond", "@fernfrond", "082 123 4567" ], @seller.links.map(&:text)
    assert_equal "https://wa.me/27821234567", @seller.links.last.url

    assert_equal "https://www.instagram.com/plantshop", Seller::Identity.instagram("https://www.instagram.com/plantshop/")
    assert_equal "+27821234567", Seller::Identity.whatsapp("+27 82 123 4567")
  end

  test "a link for the wrong site or a number that isn't South African is refused" do
    @seller.assign_attributes(instagram_url: "https://www.facebook.com/fernfrond", youtube_url: "https://www.youtube.com/watch?v=abc", whatsapp_number: "12345")
    assert_not @seller.valid?
    assert_includes @seller.errors[:instagram_url], "must be an Instagram @handle or instagram.com link"
    assert_includes @seller.errors[:youtube_url], "must be a YouTube @handle or youtube.com link"
    assert_includes @seller.errors[:whatsapp_number], "must be a South African number, like 082 123 4567"
  end

  test "hidden and empty links never show, and the card shows one chosen link (BR01, D252, D253)" do
    @seller.update!(instagram_url: "@plantshop", whatsapp_number: "0821234567", show_whatsapp: false, card_link: "instagram")
    assert_equal [ "instagram" ], @seller.shown_links.map(&:key)
    assert_equal "Fern & Frond · @plantshop", @seller.card_label

    @seller.update!(card_link: "whatsapp")
    assert_equal "Fern & Frond", @seller.card_label

    Flipper.disable("seller.social_links")
    assert_empty @seller.shown_links
  end
end
