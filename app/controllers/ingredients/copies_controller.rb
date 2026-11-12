# Copies a built-in ingredient to the collector's own list, to edit (D96).
class Ingredients::CopiesController < ApplicationController
  requires_capability "substrate.ingredients"

  def create
    source = Ingredient.built_in.find(params[:ingredient_id])
    authorize! source, to: :copy?
    copy = source.copy_for!(Current.user)
    redirect_to edit_ingredient_path(copy), notice: "Copied to your ingredients. Change what you need."
  end
end
