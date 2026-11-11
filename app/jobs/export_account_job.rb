# Builds an account export, stores it privately and emails a 7-day download link (D68).
class ExportAccountJob < ApplicationJob
  queue_as :default

  def perform(data_request)
    return unless data_request.export? && data_request.open?

    export = AccountExport.new(data_request.user)
    data_request.export_file.attach(io: StringIO.new(export.to_zip), filename: export.filename, content_type: "application/zip")
    data_request.close!(:completed, outcome: "Export prepared and emailed.")
    PrivacyMailer.export_ready(data_request).deliver_later
  end
end
