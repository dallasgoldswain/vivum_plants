require "test_helper"

class AuditTest < ActiveSupport::TestCase
  test "records actor, target and request details" do
    Current.session = users(:owner).sessions.create!
    Current.ip_address = "203.0.113.7"
    Current.request_id = "req-1"

    event = Audit.record("madmin.update", target: users(:collector), details: { changes: { "platform_operator" => [ false, true ] } })

    assert_equal users(:owner), event.actor
    assert_equal [ "User", users(:collector).id ], [ event.target_type, event.target_id ]
    assert_equal({ "changes" => { "platform_operator" => [ false, true ] } }, event.details)
    assert_equal "203.0.113.7", event.ip_address
    assert_equal "req-1", event.request_id
  end

  test "filters secrets as a backstop" do
    event = Audit.record("test.event", actor: nil, details: { values: { "password_digest" => [ "a", "b" ], "otp_secret" => [ nil, "S" ] }, code: "123456" })

    assert_equal "[FILTERED]", event.details["values"]["password_digest"]
    assert_equal "[FILTERED]", event.details["values"]["otp_secret"]
    assert_equal "[FILTERED]", event.details["code"]
  end

  test "email fingerprints are stable, normalised and not the address" do
    fingerprint = Audit.email_fingerprint(" Collector@Example.com ")

    assert_equal Audit.email_fingerprint("collector@example.com"), fingerprint
    assert_not_equal Audit.email_fingerprint("other@example.com"), fingerprint
    assert_match(/\A\h{64}\z/, fingerprint)
    assert_not_includes fingerprint, "collector"
    assert_nil Audit.email_fingerprint("  ")
  end

  test "saved events are read-only in Ruby" do
    event = Audit.record("test.event", actor: nil)
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.update!(action: "changed") }
  end

  test "the database rejects updates and early deletes" do
    event = Audit.record("test.event", actor: nil)

    assert_raises(ActiveRecord::StatementInvalid) { AuditEvent.where(id: event.id).update_all(action: "changed") }
    assert_raises(ActiveRecord::StatementInvalid) { AuditEvent.where(id: event.id).delete_all }
  end

  test "the purge job deletes only events past retention" do
    old = AuditEvent.create!(action: "test.old", created_at: 25.months.ago)
    recent = Audit.record("test.recent", actor: nil)

    PurgeAuditEventsJob.perform_now

    assert_not AuditEvent.exists?(old.id)
    assert AuditEvent.exists?(recent.id)
  end

  test "flag changes are recorded with the operator; checks are not" do
    Current.session = users(:owner).sessions.create!

    assert_difference -> { AuditEvent.where(action: "flag.enable").count } do
      Flipper.enable_actor("seller.stock", sellers(:fern_and_frond))
    end
    event = AuditEvent.where(action: "flag.enable").last
    assert_equal "seller.stock", event.target_key
    assert_equal users(:owner), event.actor
    assert_equal({ "gate" => "actor", "value" => sellers(:fern_and_frond).flipper_id }, event.details)

    assert_no_difference -> { AuditEvent.count } do
      Flipper.enabled?("seller.stock", sellers(:fern_and_frond))
    end
  end
end
