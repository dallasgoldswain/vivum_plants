require "test_helper"

class WhatsNewTest < ActiveSupport::TestCase
  test "a user who has never opened the page has something new" do
    assert WhatsNew.unseen_by?(users(:collector))
    assert_not WhatsNew.unseen_by?(nil)
  end

  test "a dated entry newer than the last visit shows the dot again" do
    user = users(:collector)
    user.update!(whats_new_seen_at: Date.new(2026, 11, 1).noon)

    Tempfile.create([ "whats_new", ".md" ]) do |file|
      file.write("# What's new\n\n## 2026-11-20\n\n- Something new\n\n## 2026-10-01\n\n- Older\n")
      file.flush
      WhatsNew.path = file.path

      assert_equal Date.new(2026, 11, 20), WhatsNew.published_on
      assert WhatsNew.unseen_by?(user)
      user.update!(whats_new_seen_at: Date.new(2026, 11, 20).noon)
      assert_not WhatsNew.unseen_by?(user)
    ensure
      WhatsNew.path = nil
    end
  end
end
