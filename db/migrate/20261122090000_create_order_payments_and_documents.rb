# Manual payments, refunds, receipts, tax invoices, credit notes and returns (B23,
# D189–D198). Payments are never edited, only voided. Receipts and credit notes share one
# gap-free number sequence per seller and keep a frozen copy of what they show. A hold on
# an order with any payment is pinned: it never expires on its own (D190).
class CreateOrderPaymentsAndDocuments < ActiveRecord::Migration[8.1]
  def change
    change_table :sellers, bulk: true do |t|
      t.string :legal_name
      t.string :vat_number
      t.text :address
      t.string :phone
      t.string :contact_email
      t.integer :last_document_number, null: false, default: 0
    end

    create_table :order_payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :kind, null: false, default: "payment"
      t.integer :amount_cents, null: false
      t.string :method, null: false
      t.date :paid_on, null: false
      t.string :reference
      t.string :reason
      t.references :recorded_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :voided_at
      t.references :voided_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :void_reason
      t.timestamps
      t.check_constraint "amount_cents > 0", name: "order_payments_amount_positive"
    end

    create_table :order_documents do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :order_payment, foreign_key: true
      t.string :kind, null: false
      t.integer :number, null: false
      t.string :reference, null: false
      t.integer :total_cents, null: false
      t.decimal :vat_rate, precision: 5, scale: 2
      t.integer :vat_cents
      t.string :reason
      t.jsonb :details, null: false, default: {}
      t.references :issued_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :issued_at, null: false
      t.datetime :created_at, null: false
      t.index %i[ seller_id number ], unique: true
      t.index :order_id, unique: true, where: "kind = 'receipt'", name: "index_order_documents_one_receipt_per_order"
    end

    create_table :order_returns do |t|
      t.references :order_line, null: false, foreign_key: true
      t.references :stock_location, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :outcome, null: false
      t.string :reason, null: false
      t.references :member, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :created_at, null: false
      t.check_constraint "quantity > 0", name: "order_returns_quantity_positive"
    end

    add_column :stock_holds, :pinned, :boolean, null: false, default: false
  end
end
