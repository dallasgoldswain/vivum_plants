require "test_helper"

class DataRequestsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "asking for an export queues it once and the emailed link downloads it" do
    user = users(:collector)
    sign_in_as user

    perform_enqueued_jobs(only: ExportAccountJob) do
      post settings_exports_path
    end
    request = user.data_requests.export.sole
    assert request.completed?

    get settings_export_path(request.download_token)
    assert_response :success
    assert_equal "application/zip", response.media_type
  end

  test "an export link doesn't work for another account or after 7 days" do
    request = users(:collector).data_requests.create!(kind: "export")
    ExportAccountJob.perform_now(request)
    token = request.download_token

    sign_in_as users(:manager)
    get settings_export_path(token)
    assert_redirected_to settings_account_path

    sign_in_as users(:collector)
    travel 8.days
    get settings_export_path(token)
    assert_redirected_to settings_account_path
  end

  test "privacy requests are logged with a 30-day due date" do
    sign_in_as users(:collector)

    post settings_privacy_requests_path, params: { data_request: { kind: "correction", message: "My email is wrong." } }
    assert_redirected_to settings_privacy_path(anchor: "requests")

    request = users(:collector).data_requests.sole
    assert_equal "correction", request.kind
    assert_equal 30.days.from_now.to_date, request.due_on
    assert AuditEvent.exists?(action: "data_request.created", target_id: request.id)
  end

  test "the form can't create self-service kinds" do
    sign_in_as users(:collector)

    post settings_privacy_requests_path, params: { data_request: { kind: "deletion", message: "x" } }
    assert_empty users(:collector).data_requests
  end

  test "the account page shows export and deletion" do
    sign_in_as users(:collector)

    get settings_account_path
    assert_response :success
    assert_match "Export my data", response.body
    assert_match "Delete my account", response.body
  end
end
