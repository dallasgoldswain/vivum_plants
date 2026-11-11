require "test_helper"

class SellerBillingControllerTest < ActionDispatch::IntegrationTest
  setup do
    %w[ seller.workspace seller.members seller.invites ].each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
  end

  test "operators change billing in Madmin with a reason, and it's audited" do
    operator = users(:owner).tap { it.update!(platform_operator: true) }
    sign_in_as operator

    patch madmin_seller_path(@seller), params: { seller: { billing_mode: "comp", plan_id: plans(:starter).id } }
    assert_response :unprocessable_entity
    assert @seller.reload.billing_pilot?

    patch madmin_seller_path(@seller), params: { seller: { billing_mode: "comp", plan_id: plans(:starter).id, audit_reason: "Test account" } }
    assert @seller.reload.billing_comp?

    event = AuditEvent.where(action: "madmin.update", target_type: "Seller").last
    assert_equal "Test account", event.reason
    assert_equal [ "pilot", "comp" ], event.details.dig("values", "billing_mode")
  end

  test "sellers can't change their own billing" do
    sign_in_as users(:owner)
    patch madmin_seller_path(@seller), params: { seller: { billing_mode: "comp", audit_reason: "Please" } }
    assert_response :not_found
    assert @seller.reload.billing_pilot?
  end

  test "Sell home shows the plan; owners see limits and the end-of-pilot prompt" do
    @seller.update!(free_until: Date.yesterday, audit_reason: "Pilot ended")

    sign_in_as users(:owner)
    get sell_root_path
    assert_select "h2", text: /Pro/
    assert_select "dd", text: "3 of 5"
    assert_match "free pilot period has ended", response.body

    sign_in_as users(:packer)
    get sell_root_path
    assert_response :success
    assert_select "dd", count: 0
    assert_no_match "period has ended", response.body
  end

  test "owners can't invite beyond the member limit" do
    @seller.update!(plan: plans(:starter), audit_reason: "Testing")
    sign_in_as users(:owner)

    get sell_members_path
    assert_select "input[type=submit][value='Send invite'][disabled]"

    post sell_invitations_path, params: { invitation: { email_address: "extra@example.com", role: "manager" } }
    assert_not Invitation.exists?(email_address: "extra@example.com")
    assert_match "member places", flash[:alert]
  end
end
