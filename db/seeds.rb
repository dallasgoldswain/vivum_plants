# Records required in every environment. Safe to run repeatedly (bin/rails db:seed).

# Platform operator account, from credentials:
#
#   user:
#     admin_email: ...
#     admin_password: ...
#
# Creates the account once; later runs leave the password alone so a changed
# password is never reset by a deploy. Two-step sign-in is set up on first sign-in.
admin_email = Rails.application.credentials.dig(:user, :admin_email)
admin_password = Rails.application.credentials.dig(:user, :admin_password)

if admin_email.present? && admin_password.present?
  User.ensure_platform_operator!(email_address: admin_email, password: admin_password)
elsif !Rails.env.test?
  puts "Skipping admin user: set user.admin_email and user.admin_password in credentials."
end
