class CreateSellersAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :sellers do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :memberships do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end
    add_index :memberships, %i[seller_id user_id], unique: true
    add_check_constraint :memberships, "role IN ('owner', 'manager', 'host_packer')", name: "memberships_role_check"

    # The seller business a session is acting for. Access is re-checked against
    # memberships on every request, so removing a member revokes access at once.
    add_reference :sessions, :seller, foreign_key: { on_delete: :nullify }
  end
end
