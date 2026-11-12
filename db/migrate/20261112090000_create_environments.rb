# Environments, occupants, plant setups and measurements (B11, EN01–EN03, PL05, D88–D95).
class CreateEnvironments < ActiveRecord::Migration[8.1]
  def change
    create_table :environments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false
      t.text :notes
      t.decimal :length_cm, precision: 7, scale: 1
      t.decimal :width_cm, precision: 7, scale: 1
      t.decimal :height_cm, precision: 7, scale: 1
      t.decimal :volume_litres, precision: 8, scale: 1
      t.string :status, null: false, default: "active"
      t.bigint :cover_photo_id
      t.timestamps
      t.index %i[ user_id status ]
    end

    # One open assignment per plant: a plant has one current environment or none (D93).
    # Environments that have ever held a plant can't be deleted (D95), hence restrict.
    create_table :environment_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.references :environment, null: false, foreign_key: { on_delete: :restrict }
      t.date :started_on, null: false
      t.date :ended_on
      t.boolean :context_answered, null: false, default: false
      t.timestamps
      t.index :plant_id, unique: true, where: "ended_on IS NULL", name: "index_environment_assignments_one_current"
    end
    add_check_constraint :environment_assignments, "ended_on IS NULL OR ended_on >= started_on", name: "environment_assignments_dates_in_order"

    # Pot or container, size and watering method (PL05, D89). Recipe version joins with B12.
    create_table :plant_setups do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.date :started_on, null: false
      t.string :container
      t.decimal :size, precision: 7, scale: 1
      t.string :size_unit
      t.string :watering_method
      t.timestamps
      t.index %i[ plant_id started_on ]
    end

    # Moves and setup changes on the timeline (D92).
    change_table :care_events do |t|
      t.references :environment, foreign_key: { on_delete: :nullify }
      t.references :from_environment, foreign_key: { to_table: :environments, on_delete: :nullify }
      t.references :plant_setup, foreign_key: { on_delete: :cascade }
    end

    create_table :custom_metrics do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :unit, null: false
      t.timestamps
      t.index "user_id, lower(name)", unique: true, name: "index_custom_metrics_on_user_and_name"
    end

    # A reading: several values taken at one time from one source (EN02, D90).
    create_table :measurements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :environment, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :measured_at, null: false
      t.string :source, null: false, default: "Manual"
      t.string :note
      t.string :idempotency_key, null: false
      t.timestamps
      t.index %i[ user_id idempotency_key ], unique: true
      t.index %i[ environment_id measured_at ]
    end

    # Blank values are never stored, so a missing value stays unknown (EN02).
    create_table :measurement_values do |t|
      t.references :measurement, null: false, foreign_key: { on_delete: :cascade }
      t.string :metric, null: false
      t.references :custom_metric, foreign_key: { on_delete: :cascade }
      t.decimal :value, precision: 10, scale: 2
      t.string :text_value
      t.string :unit, null: false
      t.index %i[ measurement_id metric custom_metric_id ], unique: true, nulls_not_distinct: true, name: "index_measurement_values_one_per_metric"
    end
    add_check_constraint :measurement_values, "value IS NOT NULL OR text_value IS NOT NULL", name: "measurement_values_present"

    # Photos belong to a plant or an environment (D94).
    change_column_null :photos, :plant_id, true
    add_reference :photos, :environment, foreign_key: { on_delete: :cascade }
    add_check_constraint :photos, "num_nonnulls(plant_id, environment_id) = 1", name: "photos_one_subject"
    add_foreign_key :environments, :photos, column: :cover_photo_id, on_delete: :nullify
  end
end
