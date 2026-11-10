# One append-only audit record (PRD PR08, FF04; D49–D52). Write through Audit.record.
# The database rejects updates, and deletes younger than RETENTION.
class AuditEvent < ApplicationRecord
  RETENTION = 2.years

  belongs_to :actor, class_name: "User", optional: true

  scope :expired, -> { where(created_at: ...RETENTION.ago) }

  def readonly?
    persisted?
  end

  def target
    target_key.presence || (target_type && "#{target_type} ##{target_id}")
  end
end
