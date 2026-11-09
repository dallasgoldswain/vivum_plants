class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.mailer_from.presence || "VIVUM <no-reply@example.com>" }
  layout "mailer"
end
