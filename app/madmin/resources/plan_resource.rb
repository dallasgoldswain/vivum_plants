# Seller plans (SB01, D65): operators change prices and limits here, without a release.
# Prices are in cents (R199 = 19900). Plans in use can't be deleted.
class PlanResource < Madmin::Resource
  attribute :id, form: false
  attribute :key
  attribute :name
  attribute :monthly_price_cents
  attribute :member_limit
  attribute :photo_limit, index: false
  attribute :ai_extractions_per_month, index: false
  attribute :paid_branding
  attribute :active
  attribute :created_at, form: false
  attribute :updated_at, form: false

  attribute :sellers, form: false

  def self.display_name(record) = record.name
end
