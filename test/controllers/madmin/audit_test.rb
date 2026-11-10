require "test_helper"

class Madmin::AuditTest < ActionDispatch::IntegrationTest
  setup do
    @operator = users(:owner)
    @operator.update!(platform_operator: true)
    sign_in_as @operator
  end

  test "viewing records is audited" do
    get madmin_users_path
    get madmin_user_path(users(:collector))

    assert AuditEvent.exists?(action: "madmin.index", target_key: "User", actor_id: @operator.id)
    assert AuditEvent.exists?(action: "madmin.show", target_type: "User", target_id: users(:collector).id, actor_id: @operator.id)
  end

  test "changes to personal fields record the field name only" do
    patch madmin_user_path(users(:collector)), params: { user: { email_address: "renamed@example.com" } }

    event = AuditEvent.find_by!(action: "madmin.update")
    assert_equal [ "email_address" ], event.details["changed_fields"]
    assert_empty event.details["values"]
    assert_not_includes event.details.to_json, "renamed@example.com"
    assert_equal @operator, event.actor
  end

  test "changes to allowlisted fields keep before and after values" do
    patch madmin_user_path(users(:collector)), params: { user: { platform_operator: "1" } }

    event = AuditEvent.find_by!(action: "madmin.update")
    assert_equal [ false, true ], event.details["values"]["platform_operator"]
  end

  test "searches record that a search happened, not the search text" do
    get madmin_users_path(q: "collector@example.com")

    event = AuditEvent.find_by!(action: "madmin.index")
    assert_equal true, event.details["searched"]
    assert_not_includes event.details.to_json, "collector@example.com"
  end

  test "deletes record the type and id only" do
    seller = Seller.create!(name: "Short-lived Nursery")
    delete madmin_seller_path(seller)

    event = AuditEvent.find_by!(action: "madmin.destroy")
    assert_equal [ "Seller", seller.id ], [ event.target_type, event.target_id ]
    assert_empty event.details
  end

  test "the audit log is readable by operators and read-only" do
    Audit.record("test.event", actor: nil)

    get madmin_audit_events_path
    assert_response :success
    assert_includes response.body, "test.event"
  end

  test "non-operators can't read the audit log" do
    sign_in_as users(:collector)
    get madmin_audit_events_path
    assert_response :not_found
  end
end
