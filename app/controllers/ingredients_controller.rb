# The ingredient library: built-ins everyone can read and copy, and the collector's own
# generic or branded ingredients (SU01, D96, D97).
class IngredientsController < ApplicationController
  requires_capability "substrate.ingredients"
  before_action :set_ingredient, only: :show
  before_action :set_personal_ingredient, only: %i[ edit update ]

  def index
    authorize! Ingredient
    @show_archived = params[:archived] == "1"
    ingredients = authorized_scope(Ingredient.all).where(status: @show_archived ? "archived" : "active").search(params[:q])
    ingredients = ingredients.where(category: params[:category]) if Ingredient::CATEGORIES.include?(params[:category])
    ingredients = params[:source] == "mine" ? ingredients.personal : (params[:source] == "built_in" ? ingredients.built_in : ingredients)
    @ingredients = ingredients.by_name
    @archived_count = Current.user.ingredients.archived.count
  end

  def show
    @recipes = Current.user.recipes.where(id: RecipeVersion.joins(:components).where(recipe_components: { ingredient_id: @ingredient.id }).select(:recipe_id)).by_name
    @copies = Current.user.ingredients.where(copied_from: @ingredient) if @ingredient.built_in?
  end

  def new
    authorize! Ingredient, to: :create?
    @ingredient = Current.user.ingredients.new
  end

  def create
    authorize! Ingredient, to: :create?
    @ingredient = Current.user.ingredients.new(ingredient_params)
    if @ingredient.save
      redirect_to @ingredient, notice: "#{@ingredient.label} added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ingredient.update(ingredient_params)
      redirect_to @ingredient, notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_ingredient
      @ingredient = Ingredient.visible_to(Current.user).find(params[:id])
      authorize! @ingredient
    end

    def set_personal_ingredient
      @ingredient = Current.user.ingredients.find(params[:id])
      authorize! @ingredient, to: :update?
    end

    def ingredient_params
      params.expect(ingredient: %i[ name manufacturer category water_retention aeration particle_min_mm particle_max_mm intended_use preparation source notes ])
    end
end
