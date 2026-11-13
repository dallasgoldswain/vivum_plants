# Guidance switches (ST01–ST04, D135–D140): the account's defaults as append-only revisions,
# and each plant's own switches with the revision they were copied from.
class AddGuidanceSettings < ActiveRecord::Migration[8.1]
  def up
    create_table :guidance_revisions do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.integer :number, null: false
      t.boolean :library, null: false, default: false
      t.boolean :ai, null: false, default: false
      t.datetime :created_at, null: false
      t.index %i[ user_id number ], unique: true
    end

    add_column :plants, :guidance_library, :boolean, null: false, default: false
    add_column :plants, :guidance_ai, :boolean, null: false, default: false
    add_reference :plants, :guidance_revision, foreign_key: true

    # Existing accounts start at revision 1 with both off (D15, D137).
    execute <<~SQL
      INSERT INTO guidance_revisions (user_id, number, library, ai, created_at)
      SELECT id, 1, FALSE, FALSE, NOW() FROM users
    SQL
    execute <<~SQL
      UPDATE plants SET guidance_revision_id = guidance_revisions.id
      FROM guidance_revisions WHERE guidance_revisions.user_id = plants.user_id
    SQL
    change_column_null :plants, :guidance_revision_id, false
  end

  def down
    remove_reference :plants, :guidance_revision, foreign_key: true
    remove_column :plants, :guidance_ai
    remove_column :plants, :guidance_library
    drop_table :guidance_revisions
  end
end
