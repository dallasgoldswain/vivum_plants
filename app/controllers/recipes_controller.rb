# Substrate recipes with numbered versions, scaling and the plants that use them
# (SU02–SU05, D98–D102).
class RecipesController < ApplicationController
  requires_capability "substrate.recipes"
  before_action :set_recipe, only: %i[ show edit update ]

  def index
    authorize! Recipe
    @show_archived = params[:archived] == "1"
    @recipes = authorized_scope(Recipe.all).where(status: @show_archived ? "archived" : "active")
      .search(params[:q]).for_context(params[:context].presence_in(Plant::GROWING_CONTEXTS)).by_use(params[:use])
      .includes(versions: { components: :ingredient }).by_name
    @in_use_now = Current.user.recipes.in_use_now.pluck(:id).to_set
    @archived_count = Current.user.recipes.archived.count
    @recipe_count = Current.user.recipes.count
  end

  def show
    @versions = @recipe.versions.includes(components: :ingredient).to_a
    @version = @versions.find { it.number.to_s == params[:version] } || @versions.last
    setups = PlantSetup.where(recipe_version: @versions).includes(:plant).chronological
    current_ids = PlantSetup.current.where(plant_id: setups.map(&:plant_id)).pluck(:id).to_set
    @plants_by_version = setups.group_by(&:recipe_version_id).transform_values do |list|
      list.group_by(&:plant).map { |plant, plant_setups| [ plant, plant_setups.first.started_on, plant_setups.any? { current_ids.include?(it.id) } ] }
    end
  end

  def new
    authorize! Recipe, to: :create?
    @recipe = Current.user.recipes.new
    @version = @recipe.versions.build(number: 1, basis: "parts")
    @version.components.build(ingredient_id: params[:ingredient_id], quantity: 1) if params[:ingredient_id]
    load_ingredients
  end

  def create
    authorize! Recipe, to: :create?
    @recipe = Current.user.recipes.new(recipe_params)
    @version = @recipe.build_revision(**version_params)
    if @recipe.save_revision(@version)
      redirect_to @recipe, notice: "#{@recipe.name} saved#{' as a draft' if @version.draft?}."
    else
      load_ingredients
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @version = @recipe.current_version
    load_ingredients
  end

  def update
    @recipe.assign_attributes(recipe_params)
    previous = @recipe.current_version
    @version = @recipe.build_revision(**version_params)
    if @recipe.save_revision(@version)
      redirect_to recipe_path(@recipe), notice: saved_message(previous)
    else
      load_ingredients
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_recipe
      @recipe = Current.user.recipes.find(params[:id])
      authorize! @recipe
    end

    def recipe_params
      params.expect(recipe: [ :name, :source, :notes, contexts: [] ])
    end

    def version_params
      version = params.fetch(:version, {}).permit(:basis, :notes, components: %i[ ingredient_id quantity ])
      components = version[:components].respond_to?(:values) ? version[:components].values : Array(version[:components])
      { basis: version[:basis], notes: version[:notes], components: components.map { it.to_h.symbolize_keys }, ready: params[:ready].present? }
    end

    # Active ingredients for the picker, plus any archived ones the version already uses.
    def load_ingredients
      used = @version&.components&.map(&:ingredient_id)
      @ingredients = Ingredient.visible_to(Current.user).where(status: "active").or(Ingredient.visible_to(Current.user).where(id: used)).by_name
    end

    def saved_message(previous)
      if previous && @version.number > previous.number
        "Saved as #{@version.label}. Plants on #{previous.label} stay on #{previous.label}."
      else
        "Saved#{' as a draft' if @version.draft?}."
      end
    end
end
