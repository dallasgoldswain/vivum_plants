require "test_helper"

class ListingTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @item = @seller.stock_items.create!(kind: "batch", name: "Pothos N'Joy", price: "450", size: "12 cm pot")
    @ledger = Stock::Ledger.new(@item, member: users(:owner))
    @ledger.receive!(quantity: 5, location: @greenhouse)
  end

  test "a listing starts from the item, gets an L- reference and never holds stock (SE03, D164)" do
    listing = Listing.from_item(@item).tap(&:save!)
    assert_equal [ "L-0001", "Pothos N'Joy", 45000 ], [ listing.reference, listing.title, listing.price_cents ]
    listing.activate!
    assert_equal [ 5, 5 ], [ listing.available, @item.totals.available ]
    listing.pause!
    assert_equal 5, @item.totals.available
  end

  test "a reserved quantity-1 listing shows 0 available, sold out, and comes back (D165)" do
    specimen = @seller.stock_items.create!(kind: "specimen", name: "Variegata", price: "900")
    ledger = Stock::Ledger.new(specimen, member: users(:owner))
    ledger.receive!(quantity: 1, location: @greenhouse)
    listing = Listing.from_item(specimen).tap(&:save!).tap(&:activate!)
    hold = ledger.hold!(quantity: 1, location: @greenhouse, held_for: "A", expires_at: 1.day.from_now)
    assert_equal [ 0, true ], [ listing.available, listing.sold_out? ]
    ledger.release!(hold)
    assert_not listing.reload.sold_out?
  end

  test "a cap limits what's shown" do
    listing = Listing.from_item(@item).tap { it.listed_quantity = 2 }.tap(&:save!)
    assert_equal 2, listing.available
  end

  test "an item has one live listing at a time" do
    Listing.from_item(@item).tap(&:save!).activate!
    second = Listing.from_item(@item)
    second.state = "active"
    assert_not second.valid?
    assert Listing.from_item(@item).valid?
  end

  test "fulfilling a listed specimen ends its listing (SE04)" do
    specimen = @seller.stock_items.create!(kind: "specimen", name: "Variegata", price: "900")
    ledger = Stock::Ledger.new(specimen, member: users(:owner))
    ledger.receive!(quantity: 1, location: @greenhouse)
    listing = Listing.from_item(specimen).tap(&:save!).tap(&:activate!)
    ledger.fulfil!(ledger.hold!(quantity: 1, location: @greenhouse, held_for: "A", expires_at: 1.day.from_now))
    assert listing.reload.ended?
  end

  test "the caption follows the template until the seller writes one (D168)" do
    @seller.update!(listing_details: "Collect in Pretoria East")
    listing = Listing.from_item(@item.reload).tap(&:save!)
    assert_equal "Pothos N'Joy\nR450 · 12 cm pot\nCollect in Pretoria East\nRef L-0001", listing.caption_text
    listing.update!(caption: "Fresh pots!")
    assert_equal "Fresh pots!", listing.caption_text
  end

  test "a listing's photos must be the item's" do
    listing = Listing.from_item(@item)
    listing.photo_ids = [ 999_999 ]
    assert_not listing.valid?
  end
end
