require "test_helper"

class ConsentsTest < ActionDispatch::IntegrationTest
  test "sign up without accepting the terms fails" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "new@example.com", password: "a-long-password", password_confirmation: "a-long-password", terms_acceptance: "0" } }
    end
    assert_response :unprocessable_entity
    assert_match "Terms of use and the privacy notice must be accepted", response.body
  end

  test "sign up records terms, privacy and the marketing opt-in" do
    post registration_path, params: { user: { email_address: "new@example.com", password: "a-long-password", password_confirmation: "a-long-password", terms_acceptance: "1", marketing_email_opt_in: "1" } }

    records = User.find_by!(email_address: "new@example.com").consent_records
    assert_equal %w[ marketing_email privacy terms ], records.pluck(:purpose).sort
    assert records.all? { it.granted? && it.source == "sign_up" && it.ip_address.present? }
  end

  test "marketing is off unless opted in" do
    post registration_path, params: { user: { email_address: "new@example.com", password: "a-long-password", password_confirmation: "a-long-password", terms_acceptance: "1" } }

    assert_not User.find_by!(email_address: "new@example.com").consented_to?(:marketing_email)
  end

  test "an account without current acceptance must accept before using the app" do
    user = users(:collector)
    user.consent_records.delete_all
    sign_in_as user

    get root_path
    assert_redirected_to new_consent_acceptance_path

    post consent_acceptance_path, params: { accept: "1" }
    assert_redirected_to root_url
    assert user.reload.required_consents_accepted?
    assert_equal %w[ re_acceptance ], user.consent_records.distinct.pluck(:source)

    get root_path
    assert_response :success
  end

  test "acceptance needs the box ticked, and sign out still works" do
    user = users(:collector)
    user.consent_records.delete_all
    sign_in_as user

    post consent_acceptance_path
    assert_redirected_to new_consent_acceptance_path
    assert_not user.reload.required_consents_accepted?

    delete session_path
    assert_redirected_to new_session_path
  end

  test "legal pages are public" do
    get legal_terms_path
    assert_response :success
    assert_match "Draft for the pilot", response.body

    get legal_privacy_path
    assert_response :success
    assert_match "Anthropic and OpenAI", response.body
  end

  test "the privacy page shows choices and history, and one action withdraws" do
    user = users(:collector)
    sign_in_as user

    patch settings_consent_path("ai_processing"), params: { granted: "1" }
    assert user.reload.consented_to?(:ai_processing)

    get settings_privacy_path
    assert_response :success
    assert_select "button", text: "Turn off"
    assert_select "table tbody tr", count: 3

    patch settings_consent_path("ai_processing"), params: { granted: "0" }
    assert_not user.reload.consented_to?(:ai_processing)
  end

  test "terms and privacy can't be withdrawn from settings" do
    sign_in_as users(:collector)

    patch settings_consent_path("terms"), params: { granted: "0" }
    assert_response :not_found
    assert users(:collector).reload.consented_to?(:terms)
  end
end
