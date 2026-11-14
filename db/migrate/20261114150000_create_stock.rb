# Seller stock (SE01, SE02, SE04, D155–D163): items with seller-unique codes, locations, an
# append-only ledger of movements, balances kept per item and location in the same
# transaction (never negative), and holds with a required expiry.
class CreateStock < ActiveRecord::Migration[8.1]
  def change
    add_column :sellers, :last_stock_number, :integer, null: false, default: 0

    create_table :stock_locations do |t|
      t.references :seller, null: false, foreign_key: true
      t.string :name, null: false
      t.datetime :archived_at
      t.timestamps
      t.index "seller_id, LOWER(name)", unique: true, name: "index_stock_locations_on_seller_and_name"
    end

    create_table :stock_items do |t|
      t.references :seller, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :code, null: false
      t.integer :number
      t.string :name, null: false
      t.string :cultivar
      t.string :botanical_name
      t.string :size
      t.integer :price_cents
      t.integer :cost_cents
      t.string :currency, null: false, default: "ZAR"
      t.text :notes
      t.references :plant, foreign_key: { on_delete: :nullify }
      t.references :moved_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :cover_photo, foreign_key: { to_table: :photos, on_delete: :nullify }
      t.datetime :archived_at
      t.timestamps
      t.index "seller_id, LOWER(code)", unique: true, name: "index_stock_items_on_seller_and_code"
      t.check_constraint "price_cents IS NULL OR price_cents >= 0", name: "stock_items_price_not_negative"
      t.check_constraint "cost_cents IS NULL OR cost_cents >= 0", name: "stock_items_cost_not_negative"
    end

    create_table :stock_balances do |t|
      t.references :stock_item, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :stock_location, null: false, foreign_key: true
      t.integer :saleable, null: false, default: 0
      t.integer :unavailable, null: false, default: 0
      t.timestamps
      t.index %i[ stock_item_id stock_location_id ], unique: true
      t.check_constraint "saleable >= 0 AND unavailable >= 0", name: "stock_balances_not_negative"
    end

    create_table :stock_holds do |t|
      t.references :stock_item, null: false, foreign_key: true
      t.references :stock_location, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :held_for, null: false
      t.datetime :expires_at, null: false
      t.string :state, null: false, default: "active"
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :resolved_at
      t.timestamps
      t.index :expires_at, where: "state = 'active'", name: "index_stock_holds_active_expiry"
      t.check_constraint "quantity > 0", name: "stock_holds_quantity_positive"
    end

    create_table :stock_movements do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :stock_item, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :quantity, null: false
      t.references :stock_location, null: false, foreign_key: true
      t.references :to_location, foreign_key: { to_table: :stock_locations }
      t.string :bucket, null: false, default: "saleable"
      t.string :reason
      t.references :stock_hold, foreign_key: true
      t.references :member, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :occurred_at, null: false
      t.datetime :created_at, null: false
      t.index %i[ stock_item_id occurred_at ]
    end

    add_reference :photos, :stock_item, foreign_key: { on_delete: :cascade }
    remove_check_constraint :photos, "num_nonnulls(plant_id, environment_id, acquisition_id) = 1", name: "photos_one_subject"
    add_check_constraint :photos, "num_nonnulls(plant_id, environment_id, acquisition_id, stock_item_id) = 1", name: "photos_one_subject"
  end
end
