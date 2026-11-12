# Ingredients, versioned substrate recipes and recipe versions on plant setups
# (B12, SU01–SU05, D96–D102).
class CreateSubstrates < ActiveRecord::Migration[8.1]
  def change
    # Built-in ingredients have no user and a key from db/seeds/ingredients.yml (D96).
    create_table :ingredients do |t|
      t.references :user, foreign_key: true
      t.string :key
      t.references :copied_from, foreign_key: { to_table: :ingredients, on_delete: :nullify }
      t.string :name, null: false
      t.string :manufacturer
      t.string :category, null: false
      t.string :water_retention
      t.string :aeration
      t.decimal :particle_min_mm, precision: 5, scale: 1
      t.decimal :particle_max_mm, precision: 5, scale: 1
      t.text :intended_use
      t.text :preparation
      t.string :source
      t.text :notes
      t.string :status, null: false, default: "active"
      t.timestamps
      t.index :key, unique: true, where: "key IS NOT NULL"
      t.index %i[ user_id status ]
    end
    add_check_constraint :ingredients, "(user_id IS NULL) = (key IS NOT NULL)", name: "ingredients_built_in_or_personal"

    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :contexts, array: true, null: false, default: []
      t.string :source
      t.text :notes
      t.string :status, null: false, default: "active"
      t.string :share_token
      t.timestamps
      t.index :share_token, unique: true, where: "share_token IS NOT NULL"
      t.index %i[ user_id status ]
    end

    # A setup keeps the exact version it was given (SU04), so a used version can't be deleted.
    create_table :recipe_versions do |t|
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :number, null: false
      t.string :basis, null: false
      t.string :state, null: false, default: "draft"
      t.text :notes
      t.timestamps
      t.index %i[ recipe_id number ], unique: true
    end

    # An ingredient used in any version can only be archived (D101), hence restrict.
    create_table :recipe_components do |t|
      t.references :recipe_version, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :ingredient, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantity, precision: 8, scale: 2, null: false
      t.integer :position, null: false, default: 0
      t.index %i[ recipe_version_id ingredient_id ], unique: true
    end
    add_check_constraint :recipe_components, "quantity > 0", name: "recipe_components_quantity_positive"

    add_reference :plant_setups, :recipe_version, foreign_key: { on_delete: :restrict }
  end
end
