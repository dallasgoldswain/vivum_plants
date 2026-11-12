# Account deletion (PRD PR07, OF01; D69–D71, D73).
#
# Requesting deletion deactivates the account at once (every session ends) and starts a
# 30-day grace period; signing in during it offers to cancel. After that, purge! wipes the
# personal data and leaves an anonymised tombstone row so audit events and other records
# that point at the user id stay meaningful ("Deleted user #id"). Consent records are kept
# as proof for the audit retention period, then purged (D70).
#
# The last owner of a seller can't delete their account (D71): seller data belongs to the
# seller and is never removed as a side effect.
module User::Deletable
  extend ActiveSupport::Concern

  DELETION_GRACE = 30.days

  class NotDeletable < StandardError; end

  included do
    has_many :data_requests, dependent: :restrict_with_exception

    scope :not_deleted, -> { where(deleted_at: nil) }
    scope :deletion_pending, -> { not_deleted.where.not(deletion_requested_at: nil) }
    scope :deletion_due, -> { deletion_pending.where(deletion_requested_at: ..DELETION_GRACE.ago) }
  end

  class_methods do
    # Daily (PrivacyHousekeepingJob). Accounts that can't be purged yet stay due and their
    # deletion request stays open, so it shows as overdue in Madmin.
    def purge_due!
      deletion_due.find_each do |user|
        user.purge!
      rescue NotDeletable => error
        Rails.logger.warn("Account #{user.id} not purged: #{error.message}")
      end
    end

    # Consent records are proof of what a person agreed to; kept with the audit log (D52).
    def purge_expired_consent_records!
      ConsentRecord.where(user: where(deleted_at: ...AuditEvent::RETENTION.ago)).delete_all
    end
  end

  def deleted? = deleted_at.present?
  def deletion_pending? = deletion_requested_at.present? && !deleted?
  def deletion_due_on = deletion_requested_at && (deletion_requested_at + DELETION_GRACE).to_date

  # Sellers this user is the only owner of. Deletion waits until each has another owner.
  def sole_owned_sellers
    Seller.where(id: memberships.owner.select(:seller_id))
      .where.not(id: Membership.owner.where.not(user_id: id).select(:seller_id))
  end

  def deletable? = !deleted? && sole_owned_sellers.none?

  def request_deletion!
    raise NotDeletable, "Make someone else an owner of #{sole_owned_sellers.map(&:name).to_sentence} first." unless deletable?

    transaction do
      update!(deletion_requested_at: Time.current)
      sessions.destroy_all
      data_requests.deletion.open.first || data_requests.create!(kind: "deletion")
      Audit.record("account.deletion_requested", actor: self, target: self)
    end
    PrivacyMailer.deletion_requested(self).deliver_later
  end

  def cancel_deletion!
    return unless deletion_pending?

    transaction do
      update!(deletion_requested_at: nil)
      data_requests.deletion.open.each { it.close!(:cancelled, outcome: "Cancelled by the account holder.") }
      Audit.record("account.deletion_cancelled", actor: self, target: self)
    end
    PrivacyMailer.deletion_cancelled(self).deliver_later
  end

  # Wipes personal data and leaves the tombstone (D70). Idempotent.
  def purge!
    return if deleted?

    address = email_address
    with_lock do
      raise NotDeletable, "sole owner of a seller" unless deletable?

      sessions.destroy_all
      otp_backup_codes.delete_all
      notifications.destroy_all
      memberships.destroy_all
      referral_codes.destroy_all
      referrals.destroy_all
      referral&.destroy!
      plants.destroy_all
      acquisitions.destroy_all
      environments.destroy_all
      custom_metrics.destroy_all
      recipes.destroy_all
      ingredients.destroy_all
      Invitation.for_email(address).update_all(email_address: tombstone_email_address)
      Invitation.pending.where(invited_by: self).update_all(revoked_at: Time.current)
      data_requests.each { it.export_file.purge }
      data_requests.update_all(message: nil)
      data_requests.deletion.open.each { it.close!(:completed, outcome: "Account deleted.") }

      update_columns(
        email_address: tombstone_email_address, password_digest: nil, email_verified_at: nil,
        platform_operator: false, otp_secret: nil, otp_enabled_at: nil, otp_last_used_at: nil,
        deleted_at: Time.current, updated_at: Time.current
      )
      Audit.record("account.purged", actor: nil, target: self)
    end
    PrivacyMailer.account_deleted(address).deliver_later
  end

  def display_label
    deleted? ? "Deleted user ##{id}" : email_address
  end

  private
    # Not an address anyone can receive mail at (.invalid is reserved), and unique.
    def tombstone_email_address = "deleted-user-#{id}@deleted.invalid"
end
