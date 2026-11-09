class SessionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :ip_address
  attribute :user_agent
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :user
  attribute :seller

  def self.readonly?
    true
  end
end
