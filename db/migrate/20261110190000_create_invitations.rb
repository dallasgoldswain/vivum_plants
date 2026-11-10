class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    # Seller invites (operator → new business owner) and staff invites (owner → member).
    create_table :invitations do |t|
      t.string :kind, null: false
      t.string :email_address, null: false
      t.string :role, null: false
      t.references :seller, foreign_key: { on_delete: :cascade } # nil until a seller invite is accepted
      t.string :business_name # seller invites
      t.references :invited_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :accepted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :invitations, :email_address
  end
end
