# Library profiles (GU01, GU03, D141–D154): the platform library, published through numbered
# versions, and each collector's own profiles (sellers' from B31). Plants link to their
# owner's profiles; accepted suggestions keep the profile they came from.
class CreateLibraryProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :library_profiles do |t|
      t.references :user, foreign_key: true
      t.references :seller, foreign_key: true
      t.string :key
      t.string :botanical_name, null: false
      t.string :synonyms, array: true, null: false, default: []
      t.string :common_names, array: true, null: false, default: []
      t.string :family
      t.jsonb :content, null: false, default: {}
      t.jsonb :references, null: false, default: []
      t.datetime :content_edited_at
      t.timestamps
      t.index :key, unique: true, where: "key IS NOT NULL"
      t.check_constraint "num_nonnulls(user_id, seller_id) <= 1", name: "library_profiles_one_owner"
      t.check_constraint "key IS NULL OR (user_id IS NULL AND seller_id IS NULL)", name: "library_profiles_key_platform_only"
    end

    create_table :library_profile_versions do |t|
      t.references :library_profile, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :number, null: false
      t.string :status, null: false, default: "draft"
      t.string :botanical_name, null: false
      t.string :synonyms, array: true, null: false, default: []
      t.string :common_names, array: true, null: false, default: []
      t.string :family
      t.jsonb :content, null: false, default: {}
      t.jsonb :references, null: false, default: []
      t.date :reviewed_on
      t.datetime :published_at
      t.references :published_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
      t.index %i[ library_profile_id number ], unique: true
      t.index :library_profile_id, unique: true, where: "status = 'published'", name: "index_library_profile_versions_one_published"
    end

    add_reference :plants, :library_profile, foreign_key: { on_delete: :nullify }
    add_reference :care_schedules, :library_profile, foreign_key: { on_delete: :nullify }
    add_column :care_schedules, :library_synced_at, :datetime

    create_table :library_dismissals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: { on_delete: :cascade }
      t.references :library_profile, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :label
      t.datetime :created_at, null: false
    end

    add_column :users, :library_choice_at, :datetime
  end
end
