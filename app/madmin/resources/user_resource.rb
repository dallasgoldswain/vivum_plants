class UserResource < Madmin::Resource
  # TOTP secrets and backup codes are never exposed here.
  # Attributes
  attribute :id, form: false
  attribute :email_address
  attribute :email_verified_at
  attribute :platform_operator
  attribute :otp_enabled_at, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :password, index: false, show: false
  attribute :password_confirmation, index: false, show: false

  # Associations
  attribute :memberships
  attribute :sellers

  def self.display_name(record) = record.email_address
end
