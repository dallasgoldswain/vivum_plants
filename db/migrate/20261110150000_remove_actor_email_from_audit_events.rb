# Minimise personal data in the audit log (D53): the actor is kept as an id only.
class RemoveActorEmailFromAuditEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :audit_events, :actor_email, :string
  end
end
