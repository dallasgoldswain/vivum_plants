# Access, correction, objection and other privacy requests (PR05, D72). Logged with a 30-day
# due date and worked by operators in Madmin.
class Settings::PrivacyRequestsController < ApplicationController
  skip_verify_authorized # acts only on Current.user
  rate_limit to: 5, within: 1.hour, with: -> { redirect_to settings_privacy_path, alert: "Try again later." }

  def create
    data_request = Current.user.data_requests.new(params.expect(data_request: %i[ kind message ]))
    unless data_request.kind.in?(DataRequest::FORM_KINDS) && data_request.save
      return redirect_to settings_privacy_path(anchor: "requests"), alert: "Choose a type and tell us what you need."
    end

    PrivacyMailer.request_received(data_request).deliver_later
    redirect_to settings_privacy_path(anchor: "requests"), notice: "Request received. We'll reply by #{l data_request.due_on, format: :long}."
  end
end
