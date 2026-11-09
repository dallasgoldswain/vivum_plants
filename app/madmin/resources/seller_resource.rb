class SellerResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :memberships
  attribute :users

  def self.display_name(record) = record.name
end
