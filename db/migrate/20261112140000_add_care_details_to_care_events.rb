# Care kinds and their optional details (CA01, D104–D106).
class AddCareDetailsToCareEvents < ActiveRecord::Migration[8.1]
  def change
    change_table :care_events, bulk: true do |t|
      t.decimal :amount, precision: 10, scale: 3
      t.string :amount_unit
      t.string :watering_method
      t.string :product
      t.string :strength
      t.string :target
      t.string :label
    end
    add_check_constraint :care_events, "amount IS NULL OR amount > 0", name: "care_events_amount_positive"
    add_index :care_events, %i[ plant_id kind occurred_at ]
  end
end
