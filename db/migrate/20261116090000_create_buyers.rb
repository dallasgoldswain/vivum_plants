# Seller-scoped buyers (BY01–BY03, D171–D178): a phone number in E.164, unique within the
# seller; delivery addresses; aliases linked only by hand; single-use verification links;
# append-only consents per buyer. Holds can be for a buyer or an alias.
class CreateBuyers < ActiveRecord::Migration[8.1]
  def change
    create_table :buyers do |t|
      t.references :seller, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :contact_preference, null: false, default: "whatsapp"
      t.datetime :verified_at
      t.string :verification_method
      t.datetime :deleted_at
      t.timestamps
      t.index %i[ seller_id phone ], unique: true, where: "phone IS NOT NULL"
      # Only a deleted buyer (D177) loses its number.
      t.check_constraint "phone IS NOT NULL OR deleted_at IS NOT NULL", name: "buyers_phone_unless_deleted"
    end

    create_table :buyer_addresses do |t|
      t.references :buyer, null: false, foreign_key: { on_delete: :cascade }
      t.string :label
      t.string :recipient, null: false
      t.string :street, null: false
      t.string :suburb
      t.string :city, null: false
      t.string :province, null: false
      t.string :postal_code, null: false
      t.boolean :default, null: false, default: false
      t.timestamps
    end

    create_table :buyer_aliases do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :buyer, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.string :group_name
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    create_table :buyer_verifications do |t|
      t.references :buyer, null: false, foreign_key: { on_delete: :cascade }
      t.string :token_digest, null: false, index: { unique: true }
      t.string :phone, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.datetime :revoked_at
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    create_table :buyer_consents do |t|
      t.references :buyer, null: false, foreign_key: { on_delete: :cascade }
      t.string :purpose, null: false
      t.string :version, null: false
      t.boolean :granted, null: false
      t.string :source, null: false
      t.string :method
      t.datetime :given_at, null: false
      t.references :recorded_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :created_at, null: false
      t.index %i[ buyer_id purpose created_at ]
    end

    add_reference :stock_holds, :buyer, foreign_key: true
    add_reference :stock_holds, :buyer_alias, foreign_key: { on_delete: :nullify }
  end
end
