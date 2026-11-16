# A seller's buyer (BY01, D171): one per phone number within the seller, never visible to
# another seller. Verified by a link the buyer opens (BY03, D173); consents are kept per
# buyer (D174). Deleting for a data request keeps an anonymised record (D177).
class Buyer < ApplicationRecord
  include Merging
  include Erasure

  CONTACT_PREFERENCES = { "whatsapp" => "WhatsApp", "call" => "Phone call", "sms" => "SMS", "email" => "Email" }.freeze
  DELETED_NAME = "Deleted buyer".freeze

  belongs_to :seller
  has_many :addresses, -> { order(default: :desc, id: :asc) }, class_name: "BuyerAddress", dependent: :delete_all
  has_many :aliases, -> { order(:name) }, class_name: "BuyerAlias", dependent: :nullify
  has_many :verifications, class_name: "BuyerVerification", dependent: :delete_all
  has_many :consents, class_name: "BuyerConsent", dependent: :delete_all
  has_many :holds, class_name: "StockHold", dependent: :restrict_with_error

  normalizes :name, with: ->(value) { value.squish }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }
  normalizes :phone, with: ->(value) { PhoneNumber.normalise(value) }

  validates :name, presence: true, length: { maximum: 120 }
  validates :phone, presence: true, unless: :deleted?
  validate :phone_in_e164
  validate :phone_unique_within_seller
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :contact_preference, inclusion: { in: CONTACT_PREFERENCES.keys }

  before_update :clear_verification, if: -> { will_save_change_to_phone? && !deleted? }

  scope :active, -> { where(deleted_at: nil) }
  scope :by_name, -> { order(Arel.sql("LOWER(buyers.name)"), :id) }

  # Name, alias or phone in any format (D171); scoped by the caller to one seller.
  def self.search(query)
    query = query.to_s.strip
    return all if query.empty?

    like = "%#{sanitize_sql_like(query.downcase)}%"
    phone = PhoneNumber.normalise(query)
    alias_match = BuyerAlias.where("buyer_aliases.buyer_id = buyers.id").where("LOWER(buyer_aliases.name) LIKE ?", like)
    matches = where("LOWER(buyers.name) LIKE ?", like).or(where("EXISTS (#{alias_match.to_sql})"))
    matches = matches.or(where("buyers.phone LIKE ?", "%#{sanitize_sql_like(phone)}%")) if query.match?(/\d{3}/)
    matches
  end

  def deleted? = deleted_at.present?
  def verified? = verified_at.present?

  def default_address = addresses.find(&:default?) || addresses.first

  def consent?(purpose)
    latest = consents.select { it.purpose == purpose.to_s }.max_by { [ it.created_at, it.id ] }
    latest&.in_force? || false
  end

  def record_consent!(purpose, granted:, source:, method: nil, given_at: Time.current, by: nil)
    consents.create!(purpose: purpose, version: BuyerConsent.purpose(purpose).version, granted: granted, source: source, method: method, given_at: given_at, recorded_by: by)
  end

  def verify!(method)
    update_columns(verified_at: Time.current, verification_method: method, updated_at: Time.current)
  end

  private
    def phone_in_e164
      return if phone.blank? || PhoneNumber.valid?(phone)

      errors.add(:phone, "isn't a phone number we recognise; use 082 123 4567 or +44 7700 900123")
    end

    def phone_unique_within_seller
      return if phone.blank?

      clash = Buyer.where(seller_id: seller_id, phone: phone).where.not(id: id).first
      errors.add(:phone, "belongs to #{clash.name}") if clash
    end

    def clear_verification
      self.verified_at = nil
      self.verification_method = nil
      verifications.open.update_all(revoked_at: Time.current)
    end
end
