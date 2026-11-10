require "test_helper"

class ConsentRecordTest < ActiveSupport::TestCase
  setup { @user = users(:collector) }

  test "fixture users have accepted the current required consents" do
    assert @user.required_consents_accepted?
  end

  test "a new version of a required document makes acceptance pending" do
    bumped = ConsentRecord::PURPOSES.merge("terms" => ConsentRecord.purpose(:terms).with(version: "0.2"))

    stub_const(ConsentRecord, :PURPOSES, bumped) do
      assert_equal [ "terms" ], @user.reload.pending_required_consents
      @user.accept_required_consents!(source: "re_acceptance")
      assert @user.required_consents_accepted?
      assert_equal "0.2", @user.consent_records.where(purpose: "terms").chronological.last.version
    end
  end

  test "withdrawing adds a record and takes effect at once" do
    @user.record_consent!(:marketing_email, granted: true, source: "settings")
    assert @user.consented_to?(:marketing_email)

    assert_difference -> { @user.consent_records.count } do
      @user.record_consent!(:marketing_email, granted: false, source: "settings")
    end
    assert_not @user.consented_to?(:marketing_email)
  end

  test "required consents can't be withdrawn" do
    assert_raises(ArgumentError) { @user.record_consent!(:terms, granted: false, source: "settings") }
  end

  test "records capture the request's IP and browser and are read-only" do
    Current.ip_address = "203.0.113.9"
    Current.user_agent = "TestBrowser"
    record = @user.record_consent!(:ai_processing, granted: true, source: "settings")

    assert_equal [ "203.0.113.9", "TestBrowser", "1" ], [ record.ip_address, record.user_agent, record.version ]
    assert_raises(ActiveRecord::ReadOnlyRecord) { record.update!(granted: false) }
  ensure
    Current.reset
  end

  test "records are deleted with the account" do
    assert_difference -> { ConsentRecord.count }, -2 do
      @user.destroy
    end
  end

  private
    def stub_const(mod, name, value)
      original = mod.const_get(name)
      mod.send(:remove_const, name)
      mod.const_set(name, value)
      yield
    ensure
      mod.send(:remove_const, name)
      mod.const_set(name, original)
    end
end
