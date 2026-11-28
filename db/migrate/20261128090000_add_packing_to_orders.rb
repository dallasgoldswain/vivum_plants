# Packed is an optional tick on a paid order before it ships (PK01, D241).
class AddPackingToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :packed_at, :datetime
    add_reference :orders, :packed_by, foreign_key: { to_table: :users, on_delete: :nullify }
  end
end
