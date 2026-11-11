require "test_helper"

class SellerBillingTest < ActiveSupport::TestCase
  setup { @seller = sellers(:fern_and_frond) }

  test "new sellers start in Pilot on Pro" do
    seller = Seller.create!(name: "New Nursery")
    assert seller.billing_pilot?
    assert_equal plans(:pro), seller.plan
  end

  test "paid can't be chosen until Paystack exists" do
    assert_not @seller.update(billing_mode: "paid", audit_reason: "Trying")
    assert_match "Paystack", @seller.errors[:billing_mode].first
  end

  test "billing changes need a reason" do
    assert_not @seller.update(plan: plans(:starter))
    assert @seller.update(plan: plans(:starter), audit_reason: "Testing Starter limits")
    assert @seller.update(name: "Fern and Frond"), "other changes don't"
  end

  test "an ended free period is flagged without changing anything else" do
    @seller.update!(free_until: Date.yesterday, audit_reason: "Pilot ends")
    assert @seller.free_period_ended?
    assert_includes Seller.free_period_ended, @seller
    assert_not sellers(:aroid_attic).free_period_ended?
  end

  test "members and pending staff invites count against the plan limit" do
    @seller.update!(plan: plans(:starter), audit_reason: "Testing")
    assert_equal 3, @seller.seats_used
    assert_not @seller.seats_available?

    invitation = Invitation.new(kind: "staff", seller: @seller, role: "manager", email_address: "extra@example.com", invited_by: users(:owner))
    assert_not invitation.valid?
    assert_match "member places", invitation.errors.full_messages.to_sentence
  end

  test "pending invites take a place until cancelled" do
    plans(:starter).update!(member_limit: 3)
    sellers(:aroid_attic).update!(plan: plans(:starter), audit_reason: "Testing")
    invitation = Invitation.create!(kind: "staff", seller: sellers(:aroid_attic), role: "host_packer", email_address: "x@example.com", invited_by: users(:unenrolled_owner))
    assert_not sellers(:aroid_attic).seats_available?

    invitation.revoke!
    assert sellers(:aroid_attic).seats_available?
  end

  test "every registry entitlement is a plan column" do
    Capabilities.registry.filter_map(&:entitlement).uniq.each do |entitlement|
      assert Plan.column_names.include?(entitlement), "plans has no #{entitlement} column"
    end
  end
end
