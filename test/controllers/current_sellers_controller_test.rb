require "test_helper"

class CurrentSellersControllerTest < ActionDispatch::IntegrationTest
  test "a member of several businesses can switch between them" do
    user = users(:manager)
    sign_in_as user
    assert_nil Current.membership, "no default when the user belongs to several sellers"

    patch current_seller_path, params: { seller_id: sellers(:aroid_attic).id }

    assert_equal sellers(:aroid_attic), user.sessions.last.reload.seller
  end

  test "cannot switch to a business you don't belong to" do
    user = users(:packer)
    sign_in_as user

    patch current_seller_path, params: { seller_id: sellers(:aroid_attic).id }

    assert_nil user.sessions.last.reload.seller_id
    assert_equal "You don't have access to that.", flash[:alert]
  end
end
