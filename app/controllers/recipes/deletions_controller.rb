# Permanent delete, only for a recipe no plant has used (D101).
class Recipes::DeletionsController < ApplicationController
  include RecipeScoped
  before_action :require_deletable

  def new
  end

  def create
    @recipe.destroy!
    redirect_to recipes_path, notice: "#{@recipe.name} deleted."
  end

  private
    def require_deletable
      return if @recipe.deletable?

      redirect_to @recipe, alert: "#{@recipe.name} has been used for plants, so it can be archived but not deleted."
    end
end
