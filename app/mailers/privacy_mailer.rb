# Emails for data subject requests and account deletion (PR05, D68–D73).
class PrivacyMailer < ApplicationMailer
  def export_ready(data_request)
    @url = settings_export_url(data_request.download_token)
    @expires_on = (data_request.completed_at + DataRequest::EXPORT_TTL).to_date
    mail subject: "Your VIVUM Plants data export is ready", to: data_request.user.email_address
  end

  def request_received(data_request)
    @data_request = data_request
    mail subject: "We've received your privacy request", to: data_request.user.email_address
  end

  def deletion_requested(user)
    @due_on = user.deletion_due_on
    @url = new_session_url
    mail subject: "Your VIVUM Plants account will be deleted on #{l @due_on, format: :long}", to: user.email_address
  end

  def deletion_cancelled(user)
    mail subject: "Your VIVUM Plants account is no longer being deleted", to: user.email_address
  end

  # Sent to the address the account had, after it has been wiped.
  def account_deleted(email_address)
    mail subject: "Your VIVUM Plants account has been deleted", to: email_address
  end
end
