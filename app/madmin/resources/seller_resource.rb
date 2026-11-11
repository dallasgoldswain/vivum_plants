class SellerResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :billing_mode, description: "Pilot and Comp are free. Paid needs Paystack (not available yet)."
  attribute :plan
  attribute :free_until, description: "Optional. Afterwards owners are asked to choose a paid plan; access isn't reduced."
  attribute :audit_reason, :text, index: false, show: false, description: "Required when changing billing mode, plan or free-until date. Kept in the audit log."
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :memberships
  attribute :users

  scope :free_period_ended

  def self.display_name(record) = record.name
end
