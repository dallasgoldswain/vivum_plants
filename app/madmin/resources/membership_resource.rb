class MembershipResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :role
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :seller
  attribute :user
end
