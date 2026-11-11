# Queues an account export and serves it from the emailed link (D68). The link is a signed
# token that expires after 7 days, and it only works for the account it was made for.
class Settings::ExportsController < ApplicationController
  skip_verify_authorized # acts only on Current.user
  rate_limit to: 5, within: 1.hour, only: :create, with: -> { redirect_to settings_account_path, alert: "Try again later." }

  def create
    data_request = Current.user.data_requests.create(kind: "export")
    if data_request.persisted?
      ExportAccountJob.perform_later(data_request)
      redirect_to settings_account_path, notice: "We're preparing your export and will email you a download link."
    else
      redirect_to settings_account_path, alert: data_request.errors.full_messages.to_sentence
    end
  end

  def show
    data_request = DataRequest.find_by_download_token(params[:token])
    unless data_request&.user == Current.user && data_request.downloadable?
      return redirect_to settings_account_path, alert: "That download link has expired. Ask for a new export below."
    end

    Audit.record("data_request.downloaded", target: data_request)
    send_data data_request.export_file.download, filename: data_request.export_file.filename.to_s, type: "application/zip", disposition: "attachment"
  end
end
