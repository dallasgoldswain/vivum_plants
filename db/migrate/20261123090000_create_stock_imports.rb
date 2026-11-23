# CSV and .xlsx stock imports (B24, IM01, IM02, D199–D208). Uploading parses the file into
# rows kept on the import; nothing touches stock until the import is committed once. The
# file itself is never stored: its checksum is kept to spot the same file twice.
class CreateStockImports < ActiveRecord::Migration[8.1]
  def change
    add_column :sellers, :last_import_number, :integer, null: false, default: 0

    create_table :stock_imports do |t|
      t.references :seller, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :reference, null: false
      t.string :state, null: false, default: "previewed"
      t.string :filename, null: false
      t.string :checksum, null: false
      t.references :stock_location, null: false, foreign_key: true
      t.boolean :add_to_existing, null: false, default: false
      t.jsonb :rows, null: false, default: []
      t.jsonb :report, null: false, default: []
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :imported_at
      t.references :imported_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :reversed_at
      t.references :reversed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
      t.index %i[ seller_id number ], unique: true
      t.index %i[ seller_id checksum ]
    end
  end
end
