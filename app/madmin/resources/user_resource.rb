class UserResource < Madmin::Resource
  # TOTP secrets and backup codes are never exposed here.
  # Attributes
  attribute :id, form: false
  attribute :email_address
  attribute :email_verified_at
  attribute :platform_operator
  attribute :otp_enabled_at, form: false
  attribute :deletion_requested_at, form: false
  attribute :deleted_at, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :password, index: false, show: false
  attribute :password_confirmation, index: false, show: false

  # Associations
  attribute :memberships
  attribute :sellers
  attribute :data_requests, form: false

  scope :deletion_pending

  # Deleted accounts show as "Deleted user #id" (D70); their email is gone.
  def self.display_name(record) = record.display_label
end
