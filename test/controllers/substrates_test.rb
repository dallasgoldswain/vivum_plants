require "test_helper"

class SubstratesTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants collection.environments collection.media substrate.ingredients substrate.recipes substrate.scaling substrate.share help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    @recipe = recipes(:aroid_mix)
    sign_in_as @user
  end

  test "substrates are hidden while their flags are off" do
    Flipper.disable("substrate.recipes")
    get recipes_path
    assert_response :not_found
    get plant_path(plants(:monstera_one))
    assert_select "#plant_setup_recipe_version_id", 0
    assert_select "a[href=?]", recipes_path, 0
  end

  test "someone else's recipe or ingredient is not found" do
    get recipe_path(recipes(:owner_mix))
    assert_response :not_found
    get ingredient_path(ingredients(:owner_moss))
    assert_response :not_found
    post recipe_share_path(recipes(:owner_mix))
    assert_response :not_found
    patch ingredient_path(ingredients(:bark)), params: { ingredient: { name: "Mine now" } }
    assert_response :not_found
  end

  test "writing a recipe in parts, then changing it once a plant uses it" do
    bark, perlite = ingredients(:bark, :perlite)
    post recipes_path, params: {
      recipe: { name: "Hoya mix", contexts: [ "indoor", "" ] },
      version: { basis: "parts", components: { "0" => { ingredient_id: bark.id, quantity: "2" }, "1" => { ingredient_id: perlite.id, quantity: "1" }, "2" => { ingredient_id: "", quantity: "" } } },
      ready: "1"
    }
    recipe = @user.recipes.find_by!(name: "Hoya mix")
    assert_redirected_to recipe_path(recipe)
    assert recipe.current_version.ready?
    follow_redirect!
    assert_select "#composition td", "66.7%"
    assert_equal [ "650 mL", "350 mL" ], css_select("#scale [data-scale-target=volume]").map { it.text.strip }

    plant = plants(:monstera_one)
    post plant_setups_path(plant), params: { plant_setup: { container: "Clay pot", recipe_version_id: recipe.current_version.id, started_on: Date.current.iso8601 } }
    follow_redirect!
    assert_match "Clay pot · Hoya mix v1", response.body

    get edit_recipe_path(recipe)
    assert_select "h2", "Saving a change makes v2"
    patch recipe_path(recipe), params: {
      recipe: { name: "Hoya mix" },
      version: { basis: "parts", components: { "0" => { ingredient_id: bark.id, quantity: "3" }, "1" => { ingredient_id: perlite.id, quantity: "1" } } },
      ready: "1"
    }
    assert_equal "Saved as v2. Plants on v1 stay on v1.", flash[:notice]
    assert_equal 1, plant.reload.current_setup.recipe_version.number

    get recipe_path(recipe, version: 1)
    assert_select "h2", "You're looking at v1"
    assert_match "in it now", response.body
  end

  test "a % recipe at 95% can't be marked ready" do
    post recipes_path, params: {
      recipe: { name: "Gritty" },
      version: { basis: "percent", components: { "0" => { ingredient_id: ingredients(:bark).id, quantity: "95" } } },
      ready: "1"
    }
    assert_response :unprocessable_entity
    assert_match "add up to 95%", response.body
  end

  test "the setup picker offers ready versions only" do
    get plant_path(plants(:monstera_one))
    assert_select "#plant_setup_recipe_version_id option", text: "Aroid mix v1"

    @user.recipes.create!(name: "Draft mix").then { it.save_revision(it.build_revision(basis: "parts", notes: nil, ready: false, components: [ { ingredient_id: ingredients(:bark).id, quantity: 1 } ])) }
    get plant_path(plants(:monstera_one))
    assert_select "#plant_setup_recipe_version_id option", text: /Draft mix/, count: 0
  end

  test "built-ins can be copied but not edited; personal ingredients can" do
    bark = ingredients(:bark)
    get ingredient_path(bark)
    assert_select "button", "Copy to mine"
    assert_select "a", text: "Edit", count: 0

    post ingredient_copy_path(bark)
    copy = @user.ingredients.order(:id).last
    assert_redirected_to edit_ingredient_path(copy)
    patch ingredient_path(copy), params: { ingredient: { name: "Bark, sieved", manufacturer: "Orchiata" } }
    assert_equal "Bark, sieved (Orchiata)", copy.reload.label
    assert_equal "Orchid bark, medium", bark.reload.name

    get ingredients_path(q: "orchiata")
    assert_select ".vv-plant-row", 1
  end

  test "an unused ingredient or recipe can be deleted; a used one only archived" do
    pumice = ingredients(:branded_pumice)
    post ingredient_deletion_path(pumice)
    assert_not Ingredient.exists?(pumice.id)

    post recipe_deletion_path(@recipe)
    assert_not Recipe.exists?(@recipe.id)

    recipe = @user.recipes.create!(name: "Used").tap { it.save_revision(it.build_revision(basis: "parts", notes: nil, ready: true, components: [ { ingredient_id: ingredients(:perlite).id, quantity: 1 } ])) }
    plants(:monstera_one).change_setup!({ recipe_version_id: recipe.current_version.id })
    post recipe_deletion_path(recipe)
    assert_match "can be archived but not deleted", flash[:alert]
    post recipe_archive_path(recipe)
    assert recipe.reload.archived?
    get plant_path(plants(:monstera_one))
    assert_match "Used v1", response.body
  end

  test "a shared link opens signed out, shows no notes, and stops working once turned off" do
    @recipe.update!(notes: "Bought the bark at the market stall")
    recipe_versions(:aroid_v1).update!(notes: "Soak the bark overnight")
    post recipe_share_path(@recipe)
    token = @recipe.reload.share_token
    assert token.present?

    sign_out
    get shared_recipe_path(token)
    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "h1", /Aroid mix/
    assert_match "Soak the bark overnight", response.body
    assert_no_match "market stall", response.body
    assert_no_match "Monstera", response.body

    sign_in_as @user
    delete recipe_share_path(@recipe)
    sign_out
    get shared_recipe_path(token)
    assert_response :not_found
  end

  test "a shared link stops working when the owner loses the share flag or archives the recipe" do
    @recipe.share!
    Flipper.disable("substrate.share")
    get shared_recipe_path(@recipe.share_token)
    assert_response :not_found

    Flipper.enable("substrate.share")
    @recipe.update!(status: "archived")
    get shared_recipe_path(@recipe.share_token)
    assert_response :not_found
  end

  test "recipes list searches by ingredient and filters by context" do
    get recipes_path(q: "coir")
    assert_select ".vv-plant-row", 1
    get recipes_path(context: "aquatic")
    assert_select ".vv-plant-row", 0
  end
end
