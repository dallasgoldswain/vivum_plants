# Records required in every environment. Safe to run repeatedly (bin/rails db:seed).

# Seller plans (SB01, D21, D65). Created once; operators edit prices and limits in /madmin.
{
  "starter" => { name: "Starter", monthly_price_cents: 19_900, member_limit: 2, photo_limit: 2_000, ai_extractions_per_month: 1_000, paid_branding: false },
  "pro" => { name: "Pro", monthly_price_cents: 44_900, member_limit: 5, photo_limit: 10_000, ai_extractions_per_month: 5_000, paid_branding: true }
}.each do |key, attrs|
  Plan.find_or_create_by!(key: key) { it.assign_attributes(attrs) }
end

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

# Built-in substrate ingredients (D96), from db/seeds/ingredients.yml. Matched by key, so
# edits to the file update them; removed entries are archived.
Ingredient.sync_built_ins!

# Feature flags: add every registered capability to Flipper so the console lists them.
# In development, implemented core capabilities are switched on (PRD FF02).
Capabilities.sync!
