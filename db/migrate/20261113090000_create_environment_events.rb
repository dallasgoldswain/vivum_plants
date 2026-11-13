# Environment maintenance (EN04, D121–D126): one event per environment, linked to the plants
# present then, and reminders that belong to a plant or an environment.
class CreateEnvironmentEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :environment_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :environment, null: false, foreign_key: true
      t.references :care_task, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.string :kind, null: false
      t.string :label
      t.datetime :occurred_at, null: false
      t.text :note
      t.decimal :amount, precision: 10, scale: 3
      t.string :amount_unit
      t.string :product
      t.string :idempotency_key, null: false
      t.timestamps
      t.index %i[ user_id idempotency_key ], unique: true
      t.index %i[ environment_id occurred_at ]
      t.check_constraint "amount IS NULL OR amount > 0", name: "environment_events_amount_positive"
    end

    create_table :environment_event_plants do |t|
      t.references :environment_event, null: false, foreign_key: { on_delete: :cascade }
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.index %i[ environment_event_id plant_id ], unique: true
    end

    add_reference :photos, :environment_event, foreign_key: { on_delete: :cascade }

    change_column_null :care_schedules, :plant_id, true
    add_reference :care_schedules, :environment, foreign_key: true
    add_check_constraint :care_schedules, "num_nonnulls(plant_id, environment_id) = 1", name: "care_schedules_one_subject"
    change_column_null :care_tasks, :plant_id, true
    add_reference :care_tasks, :environment, foreign_key: true
    add_check_constraint :care_tasks, "num_nonnulls(plant_id, environment_id) = 1", name: "care_tasks_one_subject"
  end
end
