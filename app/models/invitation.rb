# An invitation to a seller business (SO02, SO03, D58–D63).
#
# - seller: a platform operator invites someone to start a new business as its owner.
# - staff:  an owner invites someone to an existing business with a role.
#
# Only an account with the invited email address can accept (D58). Links are signed tokens,
# not stored: resending moves expires_at, which voids every earlier link (D59).
class Invitation < ApplicationRecord
  TTL = 14.days

  class NotAcceptable < StandardError; end

  enum :kind, { seller: "seller", staff: "staff" }, validate: true
  enum :role, Membership.roles, validate: true, prefix: true

  belongs_to :seller, optional: true
  belongs_to :invited_by, class_name: "User", optional: true # nil once the inviter's account is deleted
  belongs_to :accepted_by, class_name: "User", optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :business_name, presence: true, if: :seller?
  validates :seller, presence: true, if: :staff?
  validates :invited_by, presence: true, on: :create
  validate :seller_invites_are_for_owners
  validate :not_already_a_member, :no_other_pending_invite, on: :create

  before_validation -> { self.expires_at ||= TTL.from_now }, on: :create
  after_create -> { audit("invitation.created") }

  generates_token_for :acceptance do
    [ expires_at.to_i, accepted_at, revoked_at ]
  end

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil).where(expires_at: Time.current..) }
  scope :for_email, ->(email) { where(email_address: email.to_s.strip.downcase) }

  def self.find_by_token(token) = find_by_token_for(:acceptance, token)

  def pending?
    accepted_at.nil? && revoked_at.nil? && !expired?
  end

  def expired?
    expires_at.past?
  end

  def status
    if accepted_at then "accepted"
    elsif revoked_at then "revoked"
    elsif expired? then "expired"
    else "pending"
    end
  end

  def acceptance_token = generate_token_for(:acceptance)

  def business_label = seller&.name || business_name

  def deliver_later
    InvitationMailer.invite(self).deliver_later
  end

  # New link and a fresh 14 days; earlier links stop working.
  def resend!
    raise NotAcceptable, "This invite has already been used or cancelled." if accepted_at || revoked_at

    update!(expires_at: TTL.from_now)
    audit("invitation.resent")
    deliver_later
  end

  def revoke!
    return if revoked_at || accepted_at

    update!(revoked_at: Time.current)
    audit("invitation.revoked")
  end

  # Creates the business (seller invites) and the membership. Becoming an owner means
  # accepting the seller terms (D60). Returns the new membership.
  def accept!(user, business_name: nil, seller_terms: false)
    transaction do
      lock!
      raise NotAcceptable, "This invite is no longer valid." unless pending?
      raise NotAcceptable, "This invite was sent to a different email address." unless for?(user)
      raise NotAcceptable, "Accept the seller terms to continue." if role_owner? && !seller_terms

      raise NotAcceptable, "You already belong to #{seller.name}." if seller&.users&.exists?(user.id)

      self.seller ||= Seller.create!(name: business_name.presence || self.business_name)
      membership = seller.memberships.create!(user: user, role: role)
      user.record_consent!(:seller_terms, granted: true, source: "invitation") if role_owner?
      update!(accepted_at: Time.current, accepted_by: user)
      audit("invitation.accepted", actor: user)
      membership
    end
  rescue ActiveRecord::RecordInvalid => error
    raise NotAcceptable, error.record.errors.full_messages.to_sentence
  end

  def for?(user)
    user.present? && user.email_verified? && user.email_address == email_address
  end

  private
    def audit(action, actor: Current.user)
      Audit.record(action, actor: actor, target: self, details: { kind: kind, role: role, seller_id: seller_id }.compact)
    end

    def seller_invites_are_for_owners
      errors.add(:role, "must be owner for a new business") if seller? && !role_owner?
    end

    def not_already_a_member
      return unless staff? && seller

      errors.add(:email_address, "already belongs to this business") if seller.users.exists?(email_address: email_address)
    end

    def no_other_pending_invite
      others = Invitation.pending.for_email(email_address).where(kind: kind)
      others = others.where(seller_id: seller_id) if staff?
      errors.add(:email_address, "already has a pending invite") if others.exists?
    end
end
