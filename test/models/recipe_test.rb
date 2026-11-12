require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @recipe = recipes(:aroid_mix)
    @bark, @perlite, @coir = ingredients(:bark, :perlite, :coir)
  end

  test "2 bark : 1 perlite : 1 coir is 50/25/25%" do
    version = recipe_versions(:aroid_v1)
    assert_equal [ 0.5, 0.25, 0.25 ], version.components.map { version.fraction_for(it).to_f }
  end

  test "2:1:1 scaled to 4 L gives 2 L, 1 L and 1 L (AT09)" do
    scale = Recipe::Scale.new(recipe_versions(:aroid_v1), 4000)
    assert_equal [ 2000, 1000, 1000 ], scale.lines.map(&:millilitres)
    assert_equal 4000, scale.total_ml
  end

  test "scaling rounds to 50 mL, or 25 mL under 1 L, and shows the rounded total" do
    version = build_revision(@user.recipes.new(name: "Thirds"), [ [ @bark, 1 ], [ @perlite, 1 ], [ @coir, 1 ] ])

    assert_equal [ 350, 350, 350 ], Recipe::Scale.new(version, 1000).lines.map(&:millilitres)
    assert_equal 1050, Recipe::Scale.new(version, 1000).total_ml
    assert_equal [ 175, 175, 175 ], Recipe::Scale.new(version, 500).lines.map(&:millilitres)
  end

  test "a % recipe must total 100% before it's ready; a draft can be saved first" do
    recipe = @user.recipes.new(name: "Gritty")
    version = build_revision(recipe, [ [ @bark, 50 ], [ @perlite, 45 ] ], basis: "percent", ready: true)
    assert_not recipe.save_revision(version)
    assert_match "add up to 95%", version.errors.full_messages.to_sentence

    version = build_revision(recipe, [ [ @bark, 50 ], [ @perlite, 45 ] ], basis: "percent", ready: false)
    assert recipe.save_revision(version)
    assert version.draft?
  end

  test "a plant on v1 stays on v1 after v2 is saved, and its old setup still shows v1 (SU04)" do
    plant = plants(:monstera_one)
    v1 = recipe_versions(:aroid_v1)
    plant.change_setup!({ recipe_version_id: v1.id }, on: 10.days.ago.to_date)

    v2 = build_revision(@recipe, [ [ @bark, 3 ], [ @perlite, 1 ] ])
    assert @recipe.save_revision(v2)
    assert_equal 2, v2.number
    assert_equal [ 2, 1, 1 ], v1.reload.components.map { it.quantity.to_i }
    assert_equal v1, plant.reload.current_setup.recipe_version
  end

  test "an unused version is edited in place, and saving an in-use one unchanged makes nothing new" do
    version = build_revision(@recipe, [ [ @bark, 1 ], [ @perlite, 1 ] ])
    assert @recipe.save_revision(version)
    assert_equal [ 1 ], @recipe.versions.reload.map(&:number)

    plants(:monstera_one).change_setup!({ recipe_version_id: version.id })
    same = build_revision(@recipe.reload, [ [ @bark, 1 ], [ @perlite, 1 ] ])
    assert_equal version, same
    assert @recipe.save_revision(same)
    assert_equal 1, @recipe.versions.reload.count
  end

  test "a draft can't be given to a plant, and nor can someone else's recipe" do
    draft = build_revision(@user.recipes.new(name: "Work in progress"), [ [ @bark, 1 ] ], ready: false)
    draft.recipe.save_revision(draft)

    assert_raises(ActiveRecord::RecordInvalid) { plants(:monstera_one).change_setup!({ recipe_version_id: draft.id }) }
    assert_raises(ActiveRecord::RecordInvalid) { plants(:monstera_one).change_setup!({ recipe_version_id: recipe_versions(:owner_v1).id }) }
  end

  test "ingredients must be built-in or ours, and listed once" do
    version = build_revision(@user.recipes.new(name: "X"), [ [ ingredients(:owner_moss), 1 ] ])
    assert_not version.valid?
    assert_match "from your list", version.errors.full_messages.to_sentence

    version = build_revision(@user.recipes.new(name: "Y"), [ [ @bark, 1 ], [ @bark, 2 ] ])
    assert_not version.valid?
  end

  test "a used recipe can be archived but not deleted; an ingredient in a recipe can't be deleted" do
    assert @recipe.deletable?
    plants(:monstera_one).change_setup!({ recipe_version_id: recipe_versions(:aroid_v1).id })
    assert_not @recipe.reload.deletable?
    assert_raises(ActiveRecord::StatementInvalid) { Recipe.transaction(requires_new: true) { recipe_versions(:aroid_v1).delete } }

    pumice = ingredients(:branded_pumice)
    assert_not pumice.used?
    version = build_revision(@user.recipes.new(name: "Pure pumice"), [ [ pumice, 1 ] ])
    version.recipe.save_revision(version)
    assert pumice.used?
    assert_not pumice.destroy
  end

  test "filters by use and search by ingredient" do
    other = build_revision(@user.recipes.new(name: "Pure pumice"), [ [ ingredients(:branded_pumice), 1 ] ])
    other.recipe.save_revision(other)
    plant = plants(:monstera_one)
    plant.change_setup!({ recipe_version_id: recipe_versions(:aroid_v1).id }, on: 5.days.ago.to_date)

    assert_equal [ @recipe ], @user.recipes.by_use("now").to_a
    assert_equal [ other.recipe ], @user.recipes.by_use("never").to_a

    plant.change_setup!({ recipe_version_id: other.id })
    assert_equal [ @recipe ], @user.recipes.by_use("before").to_a
    assert_equal [ other.recipe ], @user.recipes.search("kiwi").to_a
    assert_equal [ @recipe ], @user.recipes.search("perlite").to_a
    assert_equal [ @recipe ], @user.recipes.for_context("indoor").to_a
  end

  test "built-ins sync from the seed file and can be copied, not edited" do
    Ingredient.sync_built_ins!
    assert_operator Ingredient.built_in.active.count, :>=, 40
    assert Ingredient.built_in.active.find_by(key: "perlite")
    assert_equal Ingredient::CATEGORIES.sort, (Ingredient.built_in.distinct.pluck(:category) | Ingredient::CATEGORIES).sort

    copy = @bark.copy_for!(@user)
    assert_equal @user, copy.user
    assert_equal @bark, copy.copied_from
    assert_nil copy.key
    assert_not IngredientPolicy.new(@bark, user: @user).apply(:update?)
    assert IngredientPolicy.new(copy, user: @user).apply(:update?)
  end

  test "a branded ingredient keeps its manufacturer and is distinct from the generic one" do
    pumice = ingredients(:branded_pumice)
    assert pumice.branded?
    assert_equal "Pumice (Kiwi Pumice Co)", pumice.label
    assert_not Ingredient.find_by(key: "pumice")&.branded?
  end

  private
    def build_revision(recipe, rows, basis: "parts", ready: true)
      recipe.build_revision(basis: basis, notes: nil, ready: ready, components: rows.map { |ingredient, quantity| { ingredient_id: ingredient.id, quantity: quantity } })
    end
end
