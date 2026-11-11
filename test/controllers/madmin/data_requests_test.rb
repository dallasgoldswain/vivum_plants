require "test_helper"

class Madmin::DataRequestsTest < ActionDispatch::IntegrationTest
  setup do
    @operator = users(:owner)
    @operator.update!(platform_operator: true)
    @data_request = users(:collector).data_requests.create!(kind: "access", message: "What do you hold?")
    sign_in_as @operator
  end

  test "operators see the queue and the overdue scope" do
    get madmin_data_requests_path
    assert_response :success

    get madmin_data_requests_path(scope: "overdue")
    assert_response :success
  end

  test "closing a request needs an outcome and records who handled it" do
    patch madmin_data_request_path(@data_request), params: { data_request: { status: "completed", outcome: "" } }
    assert @data_request.reload.open?

    patch madmin_data_request_path(@data_request), params: { data_request: { status: "completed", outcome: "Sent a summary by email." } }
    @data_request.reload
    assert @data_request.completed?
    assert_equal @operator, @data_request.handled_by
    assert @data_request.completed_at
    assert AuditEvent.exists?(action: "data_request.completed", actor_id: @operator.id, target_id: @data_request.id)
  end

  test "operators can log a request that arrived by email" do
    assert_difference -> { DataRequest.count } do
      post madmin_data_requests_path, params: { data_request: { user_id: users(:manager).id, kind: "objection", message: "Emailed: stop using my data for X." } }
    end
    assert_equal 30.days.from_now.to_date, DataRequest.last.due_on
  end

  test "deleted accounts show as deleted users" do
    user = users(:collector)
    user.request_deletion!
    travel(31.days) { User.purge_due! }

    get madmin_user_path(user)
    assert_match "Deleted user ##{user.id}", response.body
    assert_no_match "collector@example.com", response.body
  end
end
