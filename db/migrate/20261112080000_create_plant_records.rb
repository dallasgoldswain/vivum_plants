# Plant records, acquisition, status history, the care-event timeline and photos (B10, D80–D87).
class CreatePlantRecords < ActiveRecord::Migration[8.1]
  def change
    # Record numbers count up per collection and are never reused (D81).
    add_column :users, :last_plant_number, :integer, null: false, default: 0

    create_table :acquisitions do |t|
      t.references :user, null: false, foreign_key: true
      t.date :acquired_on
      t.string :source
      t.integer :cost_cents
      t.string :currency, null: false, default: "ZAR", limit: 3
      t.string :order_reference
      t.integer :quantity
      t.text :arrival_notes
      t.timestamps
    end
    add_check_constraint :acquisitions, "cost_cents IS NULL OR cost_cents >= 0", name: "acquisitions_cost_not_negative"
    add_check_constraint :acquisitions, "quantity IS NULL OR quantity >= 0", name: "acquisitions_quantity_not_negative"

    create_table :plants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :acquisition, foreign_key: { on_delete: :nullify }
      t.integer :number, null: false
      t.string :display_name, null: false
      t.string :botanical_name
      t.string :cultivar
      t.string :common_name
      t.string :nickname
      t.string :growing_context, null: false
      t.boolean :tc_origin, null: false, default: false
      t.string :origin_note
      t.integer :quantity, null: false, default: 1
      t.text :notes
      t.string :tags, array: true, null: false, default: []
      t.string :status, null: false, default: "active"
      t.date :status_on
      t.bigint :cover_photo_id
      t.timestamps
      t.index %i[ user_id number ], unique: true
      t.index %i[ user_id status ]
      t.index :tags, using: :gin
    end
    add_check_constraint :plants, "quantity >= 0", name: "plants_quantity_not_negative"

    create_table :plant_status_changes do |t|
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.string :status, null: false
      t.date :effective_on, null: false
      t.string :reason
      t.datetime :created_at, null: false
    end

    # The plant timeline (D82). Observations first; B13 adds other kinds.
    create_table :care_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false, default: "observation"
      t.text :note
      t.datetime :occurred_at, null: false
      t.string :idempotency_key, null: false
      t.timestamps
      t.index %i[ user_id idempotency_key ], unique: true
      t.index %i[ plant_id occurred_at ]
    end

    create_table :photos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.references :care_event, foreign_key: { on_delete: :cascade }
      t.string :caption
      t.date :taken_on, null: false
      t.timestamps
      t.index %i[ plant_id taken_on ]
    end
    add_foreign_key :plants, :photos, column: :cover_photo_id, on_delete: :nullify
  end
end
