class CreateConsentRecords < ActiveRecord::Migration[8.1]
  def change
    # Append-only: each grant or withdrawal is a new row; the latest row per purpose is the
    # current state. Deleted with the account (unlike audit_events).
    create_table :consent_records do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :purpose, null: false
      t.string :version, null: false
      t.boolean :granted, null: false
      t.string :source, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :created_at, null: false
    end

    add_index :consent_records, %i[ user_id purpose created_at ]
  end
end
