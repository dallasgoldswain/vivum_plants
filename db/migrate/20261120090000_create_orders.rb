# Orders (SE05, SE06, D179–D188): one seller and one buyer, numbered O-0001 per seller. Order
# state is separate from payment state. Lines snapshot the agreed price; a reserved line holds
# its stock through a stock hold. Shipping copies the buyer's address onto the order.
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :sellers, :last_order_number, :integer, null: false, default: 0

    create_table :orders do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :buyer, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :reference, null: false
      t.string :buyer_name, null: false
      t.string :source, null: false, default: "chat"
      t.string :state, null: false, default: "draft"
      t.string :payment_state, null: false, default: "unpaid"
      t.datetime :hold_expires_at
      t.string :delivery_method, null: false, default: "pickup"
      t.jsonb :shipping_address
      t.integer :shipping_cents, null: false, default: 0
      t.integer :discount_cents, null: false, default: 0
      t.string :discount_reason
      t.string :currency, null: false, default: "ZAR"
      t.text :notes
      t.string :courier
      t.string :tracking_reference
      t.datetime :fulfilled_at
      t.references :fulfilled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :cancel_reason
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
      t.index %i[ seller_id number ], unique: true
      t.check_constraint "shipping_cents >= 0 AND discount_cents >= 0", name: "orders_amounts_not_negative"
    end

    create_table :order_lines do |t|
      t.references :order, null: false, foreign_key: { on_delete: :cascade }
      t.references :stock_item, null: false, foreign_key: true
      t.references :listing, foreign_key: { on_delete: :nullify }
      t.string :description, null: false
      t.integer :quantity, null: false
      t.integer :agreed_price_cents, null: false
      t.integer :unit_price_cents, null: false
      t.string :price_reason
      t.string :state, null: false, default: "active"
      t.string :cancel_reason
      t.references :stock_hold, foreign_key: true, index: { unique: true }
      t.timestamps
      t.check_constraint "quantity > 0", name: "order_lines_quantity_positive"
      t.check_constraint "unit_price_cents >= 0 AND agreed_price_cents >= 0", name: "order_lines_prices_not_negative"
    end

    # Addresses unused on an order and unedited for 12 months are redacted (PR07, D188).
    add_column :buyer_addresses, :last_used_at, :datetime
  end
end
