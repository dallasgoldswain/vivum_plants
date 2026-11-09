class Noticed::EventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :type
  attribute :params
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :notifications_count, form: false

  # Associations
  attribute :record
  attribute :notifications

  def self.readonly?
    true
  end
end
