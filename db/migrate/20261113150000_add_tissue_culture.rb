# Purchased tissue culture (TC01–TC05, PL06, D127–D134): a purchase group is an acquisition
# that holds several plants, plantlets have a stage, checks are a care kind, and splits link
# records.
class AddTissueCulture < ActiveRecord::Migration[8.1]
  def change
    change_table :acquisitions, bulk: true do |t|
      t.string :name
      t.boolean :tissue_culture, null: false, default: false
      t.string :container_condition
      t.date :deflasked_on
      t.bigint :cover_photo_id
    end
    add_foreign_key :acquisitions, :photos, column: :cover_photo_id, on_delete: :nullify

    change_table :plants, bulk: true do |t|
      t.string :tc_stage
      t.references :split_from, foreign_key: { to_table: :plants, on_delete: :nullify }
    end

    change_table :care_events, bulk: true do |t|
      t.string :stage
      t.boolean :new_leaves, null: false, default: false
      t.boolean :new_roots, null: false, default: false
      t.boolean :damage, null: false, default: false
      t.boolean :suspected_contamination, null: false, default: false
      t.string :humidity_setup
    end

    add_column :care_schedules, :origin, :string

    add_reference :photos, :acquisition, foreign_key: { on_delete: :cascade }
    remove_check_constraint :photos, "num_nonnulls(plant_id, environment_id) = 1", name: "photos_one_subject"
    add_check_constraint :photos, "num_nonnulls(plant_id, environment_id, acquisition_id) = 1", name: "photos_one_subject"
  end
end
