# Deletes audit events past retention (2 years, D52). The database refuses younger deletes.
class PurgeAuditEventsJob < ApplicationJob
  queue_as :default

  def perform
    AuditEvent.expired.in_batches(of: 1_000).delete_all
  end
end
