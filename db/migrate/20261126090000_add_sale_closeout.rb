# Sale Closeout (SC01, SC02, D219–D224): orders made from a live session, and order lines
# that came from a lot or a claim. A line takes over the result's hold, and the existing
# unique index on order_lines.stock_hold_id keeps a result off two lines at once.
class AddSaleCloseout < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :sale_session, foreign_key: { on_delete: :nullify }
    add_reference :order_lines, :sale_lot, foreign_key: { on_delete: :nullify }
    add_reference :order_lines, :sale_claim, foreign_key: { on_delete: :nullify }
  end
end
