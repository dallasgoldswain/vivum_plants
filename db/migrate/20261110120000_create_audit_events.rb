class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      # No foreign key: deleting a user must not rewrite audit rows (they're append-only).
      t.bigint :actor_id
      t.string :actor_email
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.string :target_key
      t.jsonb :details, null: false, default: {}
      t.text :reason
      t.string :ip_address
      t.string :user_agent
      t.string :request_id
      t.datetime :created_at, null: false
    end
    add_index :audit_events, :created_at
    add_index :audit_events, :action
    add_index :audit_events, :actor_id
    add_index :audit_events, %i[ target_type target_id ]
    add_index :audit_events, :target_key

    create_function :protect_audit_events
    create_trigger :protect_audit_events, on: :audit_events
  end
end
