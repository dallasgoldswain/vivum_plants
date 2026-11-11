require "test_helper"

class AccountDeletionTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "requesting deletion switches the account off, ends sessions and logs a request" do
    user = users(:collector)
    user.sessions.create!

    assert_enqueued_emails 1 do
      user.request_deletion!
    end

    assert user.deletion_pending?
    assert_empty user.sessions
    assert_equal 30.days.from_now.to_date, user.deletion_due_on
    assert user.data_requests.deletion.open.exists?
    assert AuditEvent.exists?(action: "account.deletion_requested", target_type: "User", target_id: user.id)
  end

  test "the last owner of a seller can't delete their account" do
    user = users(:owner)

    assert_equal [ sellers(:fern_and_frond) ], user.sole_owned_sellers.to_a
    assert_raises(User::NotDeletable) { user.request_deletion! }
    assert_not user.reload.deletion_pending?
  end

  test "an owner with another owner beside them can delete" do
    memberships(:fern_manager).update!(role: "owner")

    assert users(:owner).deletable?
  end

  test "cancelling closes the request and keeps the account" do
    user = users(:collector)
    user.request_deletion!
    user.cancel_deletion!

    assert_not user.deletion_pending?
    assert_equal "cancelled", user.data_requests.deletion.sole.status
  end

  test "purge leaves an anonymised tombstone and keeps consent proof" do
    user = users(:manager)
    email = user.email_address
    user.sessions.create!
    Invitation.create!(kind: "seller", email_address: email, business_name: "Moss Corner", role: "owner", invited_by: users(:owner))
    user.request_deletion!
    travel 31.days

    assert_enqueued_email_with PrivacyMailer, :account_deleted, args: [ email ] do
      User.purge_due!
    end

    user.reload
    assert user.deleted?
    assert_equal "deleted-user-#{user.id}@deleted.invalid", user.email_address
    assert_nil user.password_digest
    assert_empty user.memberships
    assert_empty user.sessions
    assert_not User.authenticate_by(email_address: email, password: "password-long-enough")
    assert_not Invitation.for_email(email).exists?
    assert user.consent_records.exists?
    assert_equal "completed", user.data_requests.deletion.sole.status
    assert_equal "Deleted user ##{user.id}", user.display_label
  end

  test "purge waits while the user is the sole owner and leaves the request open" do
    user = users(:packer)
    user.request_deletion!
    memberships(:fern_packer).update_columns(role: "owner")
    memberships(:fern_owner).delete
    travel 31.days

    User.purge_due!

    assert_not user.reload.deleted?
    assert user.data_requests.deletion.open.exists?
  end

  test "accounts inside the grace period are not purged" do
    user = users(:collector)
    user.request_deletion!
    travel 29.days

    User.purge_due!
    assert_not user.reload.deleted?
  end

  test "consent records of long-deleted accounts are purged after the audit retention" do
    user = users(:collector)
    user.request_deletion!
    travel 31.days
    User.purge_due!
    travel AuditEvent::RETENTION + 1.day

    User.purge_expired_consent_records!
    assert_not ConsentRecord.where(user: user).exists?
  end
end
