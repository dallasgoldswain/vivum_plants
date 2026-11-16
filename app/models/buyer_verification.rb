# A single-use, expiring link that lets a buyer confirm their number (BY03, D173). Only a
# digest of the token is stored.
class BuyerVerification < ApplicationRecord
  TTL = 7.days

  belongs_to :buyer
  belongs_to :created_by, class_name: "User", optional: true

  attr_reader :token

  scope :open, -> { where(used_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue!(buyer, by:)
    token = SecureRandom.urlsafe_base64(32)
    verification = buyer.verifications.create!(token_digest: digest(token), phone: buyer.phone, expires_at: TTL.from_now, created_by: by)
    verification.instance_variable_set(:@token, token)
    verification
  end

  def self.find_by_token(token) = find_by(token_digest: digest(token.to_s))
  def self.digest(token) = OpenSSL::Digest::SHA256.hexdigest(token)

  def usable? = used_at.nil? && revoked_at.nil? && expires_at.future? && phone == buyer.phone && !buyer.deleted?

  def confirm!
    transaction do
      lock!
      return false unless usable?

      update!(used_at: Time.current)
      buyer.verify!("link")
      true
    end
  end
end
