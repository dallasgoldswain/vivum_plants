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

  test "changes are audited with before and after values" do
    patch madmin_seller_path(sellers(:aroid_attic)), params: { seller: { name: "Aroid Attic & Co" } }

    event = AuditEvent.find_by!(action: "madmin.update")
    assert_equal [ "Aroid Attic", "Aroid Attic & Co" ], event.details["changes"]["name"]
    assert_equal @operator, event.actor
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
