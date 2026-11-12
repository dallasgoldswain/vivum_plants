# Turns a recipe's public link on (or replaces it) and off (D102).
class Recipes::SharesController < ApplicationController
  include RecipeScoped
  requires_capability "substrate.share"

  def create
    @recipe.share!
    redirect_to recipe_path(@recipe, anchor: "sharing"), notice: "Link ready. Anyone with it can see this recipe."
  end

  def destroy
    @recipe.unshare!
    redirect_to recipe_path(@recipe, anchor: "sharing"), notice: "Link turned off."
  end
end
