# Listings and sale cards (SE03, SE07, SE08, D164–D170): one live listing per stock item,
# with its own reference, price and details; card images stored with what they show, so a
# later change flags them as stale.
class CreateListingsAndSaleCards < ActiveRecord::Migration[8.1]
  def change
    add_column :sellers, :last_listing_number, :integer, null: false, default: 0
    add_column :sellers, :listing_details, :text

    create_table :listings do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :stock_item, null: false, foreign_key: true, index: false
      t.integer :number, null: false
      t.string :reference, null: false
      t.string :title, null: false
      t.integer :price_cents, null: false
      t.integer :listed_quantity
      t.bigint :photo_ids, array: true, null: false, default: []
      t.string :size
      t.text :details
      t.text :caption
      t.string :state, null: false, default: "draft"
      t.datetime :ended_at
      t.timestamps
      t.index %i[ seller_id reference ], unique: true
      t.index :stock_item_id
      t.index :stock_item_id, unique: true, where: "state IN ('active', 'paused')", name: "index_listings_one_live_per_item"
      t.check_constraint "price_cents >= 0", name: "listings_price_not_negative"
      t.check_constraint "listed_quantity IS NULL OR listed_quantity > 0", name: "listings_listed_quantity_positive"
    end

    create_table :sale_cards do |t|
      t.references :listing, null: false, foreign_key: { on_delete: :cascade }
      t.string :format, null: false
      t.string :file_type, null: false
      t.integer :price_cents, null: false
      t.string :title, null: false
      t.bigint :photo_id
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
