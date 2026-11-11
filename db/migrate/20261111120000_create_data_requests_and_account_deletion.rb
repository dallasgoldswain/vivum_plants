# Data subject requests (PR05, D72) and account deletion with a 30-day grace period and an
# anonymised tombstone (PR07, D69–D70).
class CreateDataRequestsAndAccountDeletion < ActiveRecord::Migration[8.1]
  def change
    create_table :data_requests do |t|
      t.references :user, null: false, foreign_key: true # users are never hard-deleted (D70)
      t.string :kind, null: false
      t.string :status, null: false, default: "open"
      t.text :message
      t.text :outcome
      t.date :due_on, null: false
      t.references :handled_by, foreign_key: { to_table: :users }
      t.datetime :completed_at
      t.timestamps
    end
    add_index :data_requests, %i[ status due_on ]

    change_table :users, bulk: true do |t|
      t.datetime :deletion_requested_at
      t.datetime :deleted_at
      t.index :deletion_requested_at
      t.index :deleted_at
    end
    # A purged account keeps no password (D70).
    change_column_null :users, :password_digest, true
  end
end
