# Live sale sessions (B25, LS01–LS04, D209–D218). Bidding stays in the WhatsApp group; a
# session records its lots and claims, each holding stock through a StockHold. A won lot or
# a claim keeps its hold through the payment deadline and the backup window; the winner and
# backup are a buyer or an alias, with the name kept as it was when recorded.
class CreateSaleSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_sessions do |t|
      t.references :seller, null: false, foreign_key: true
      t.string :name, null: false
      t.string :channel
      t.references :host_member, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :starts_at
      t.datetime :closes_at
      t.string :status, null: false, default: "draft"
      t.integer :payment_hours
      t.integer :backup_hours
      t.datetime :went_live_at
      t.datetime :closed_at
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
      t.index %i[ seller_id status ]
    end

    create_table :sale_lots do |t|
      t.references :sale_session, null: false, foreign_key: true
      t.integer :number, null: false
      t.references :stock_item, null: false, foreign_key: true
      t.references :stock_location, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.string :state, null: false, default: "queued"
      t.references :stock_hold, foreign_key: { on_delete: :nullify }
      t.references :winner_buyer, foreign_key: { to_table: :buyers, on_delete: :nullify }
      t.references :winner_alias, foreign_key: { to_table: :buyer_aliases, on_delete: :nullify }
      t.string :winner_name
      t.integer :price_cents
      t.references :backup_buyer, foreign_key: { to_table: :buyers, on_delete: :nullify }
      t.references :backup_alias, foreign_key: { to_table: :buyer_aliases, on_delete: :nullify }
      t.string :backup_name
      t.integer :backup_bid_cents
      t.datetime :payment_due_at
      t.datetime :opened_at
      t.datetime :resolved_at
      t.datetime :transferred_at
      t.datetime :settled_at
      t.references :resolved_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :settled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
      t.index %i[ sale_session_id number ], unique: true
      t.index :sale_session_id, unique: true, where: "state = 'open'", name: "index_sale_lots_one_open_per_session"
    end

    create_table :sale_claim_items do |t|
      t.references :sale_session, null: false, foreign_key: true
      t.references :stock_item, null: false, foreign_key: true
      t.references :stock_location, null: false, foreign_key: true
      t.integer :price_cents, null: false
      t.datetime :removed_at
      t.timestamps
    end

    create_table :sale_claims do |t|
      t.references :sale_claim_item, null: false, foreign_key: true
      t.references :buyer, foreign_key: { on_delete: :nullify }
      t.references :buyer_alias, foreign_key: { on_delete: :nullify }
      t.string :holder_name, null: false
      t.integer :quantity, null: false
      t.string :message_reference
      t.string :state, null: false
      t.integer :position
      t.references :stock_hold, foreign_key: { on_delete: :nullify }
      t.datetime :payment_due_at
      t.datetime :settled_at
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :settled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
