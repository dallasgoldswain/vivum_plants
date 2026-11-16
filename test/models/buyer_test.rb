require "test_helper"

class BuyerTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @other = sellers(:aroid_attic)
  end

  test "local numbers are stored in E.164 and match in any format (D171)" do
    buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "082 123 4567")
    assert_equal "+27821234567", buyer.phone
    assert_equal [ buyer ], @seller.buyers.search("0821234567").to_a
    assert_equal [ buyer ], @seller.buyers.search("+27 82 123 4567").to_a
    assert_equal "+44770090012", PhoneNumber.normalise("0044 7700 90012")
  end

  test "a number is unique within a seller only, and the clash names the buyer" do
    @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    duplicate = @seller.buyers.new(name: "Sam D", phone: "+27821234567")
    assert_not duplicate.valid?
    assert_includes duplicate.errors.full_messages, "Phone belongs to Sam Dlamini"
    assert @other.buyers.create!(name: "Sam", phone: "0821234567").persisted?
  end

  test "seller A can't find seller B's buyer by phone" do
    @other.buyers.create!(name: "Lee", phone: "0839998888")
    assert_empty @seller.buyers.search("0839998888")
  end

  test "two Sam aliases stay separate until linked (BY02)" do
    buyer = @seller.buyers.create!(name: "Sam", phone: "0821234567")
    first = @seller.buyer_aliases.create!(name: "Sam")
    second = @seller.buyer_aliases.create!(name: "Sam", group_name: "Sunday auction")
    assert_nil first.buyer
    assert_nil second.buyer
    first.update!(buyer: buyer)
    assert_equal [ first ], buyer.aliases.to_a
    assert_nil second.reload.buyer
  end

  test "an alias can't link to another seller's buyer" do
    buyer = @other.buyers.create!(name: "Sam", phone: "0821234567")
    assert_not @seller.buyer_aliases.new(name: "Sam", buyer: buyer).valid?
  end

  test "a verification link works once, expires, and changing the number clears verification (BY03)" do
    buyer = @seller.buyers.create!(name: "Sam", phone: "0821234567")
    verification = BuyerVerification.issue!(buyer, by: users(:owner))
    assert_not_equal verification.token, verification.token_digest
    found = BuyerVerification.find_by_token(verification.token)
    assert found.confirm!
    assert buyer.reload.verified?
    assert_not found.reload.confirm!

    stale = BuyerVerification.issue!(buyer, by: users(:owner))
    travel BuyerVerification::TTL + 1.minute do
      assert_not stale.reload.usable?
    end

    open = BuyerVerification.issue!(buyer, by: users(:owner))
    buyer.update!(phone: "0831112222")
    assert_not buyer.reload.verified?
    assert_not open.reload.usable?
  end

  test "consents: marketing off by default, latest record wins (D174)" do
    buyer = @seller.buyers.create!(name: "Sam", phone: "0821234567")
    assert_not buyer.consent?(:marketing)
    buyer.record_consent!(:marketing, granted: true, source: "seller", method: "Said yes in chat", by: users(:owner))
    assert buyer.reload.consent?(:marketing)
    buyer.record_consent!(:marketing, granted: false, source: "buyer")
    assert_not buyer.reload.consent?(:marketing)
    assert_raises(ActiveRecord::RecordInvalid) { buyer.record_consent!(:whatsapp_messages, granted: true, source: "seller") }
  end

  test "merging moves aliases, holds, addresses and consents (D178)" do
    keep = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    other = @seller.buyers.create!(name: "Sammy", phone: "0831112222", email: "sam@example.com")
    other.aliases.create!(seller: @seller, name: "Sam 🌿")
    other.addresses.create!(recipient: "Sam", street: "1 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    other.record_consent!(:marketing, granted: true, source: "buyer")
    hold = hold_for(buyer: other)

    keep.merge!(other)
    assert_not Buyer.exists?(other.id)
    keep.reload
    assert_equal [ "Sam 🌿" ], keep.aliases.map(&:name)
    assert_equal keep, hold.reload.buyer
    assert_equal 1, keep.addresses.count
    assert keep.consent?(:marketing)
    assert_equal "sam@example.com", keep.email
  end

  test "deleting keeps an anonymised record and holds read Deleted buyer (D177)" do
    buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567", email: "sam@example.com")
    buyer.addresses.create!(recipient: "Sam", street: "1 Oak St", city: "Durban", province: "KwaZulu-Natal", postal_code: "4001")
    buyer_alias = @seller.buyer_aliases.create!(name: "Sam 🌿", buyer: buyer)
    hold = hold_for(buyer: buyer)

    buyer.erase!
    buyer.reload
    assert_equal [ "Deleted buyer", nil, nil ], [ buyer.name, buyer.phone, buyer.email ]
    assert_empty buyer.addresses
    assert_nil buyer_alias.reload.buyer
    assert_equal "Deleted buyer", hold.reload.holder_name
    assert_equal [ "Deleted buyer" ], hold.movements.pluck(:reason).uniq
    assert_no_match "Sam Dlamini", buyer.export_data.to_json
  end

  private
    def hold_for(**holder)
      location = @seller.stock_locations.create!(name: "Greenhouse #{SecureRandom.hex(2)}")
      item = @seller.stock_items.create!(kind: "batch", name: "Pothos")
      ledger = Stock::Ledger.new(item, member: users(:owner))
      ledger.receive!(quantity: 3, location: location)
      ledger.hold!(quantity: 1, location: location, expires_at: 1.day.from_now, **holder)
    end
end
