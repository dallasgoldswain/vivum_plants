# Permanent delete, only for a personal ingredient no recipe has used (D101).
class Ingredients::DeletionsController < ApplicationController
  include IngredientScoped
  before_action :require_unused

  def new
  end

  def create
    @ingredient.destroy!
    redirect_to ingredients_path, notice: "#{@ingredient.label} deleted."
  end

  private
    def require_unused
      return unless @ingredient.used?

      redirect_to @ingredient, alert: "#{@ingredient.label} is in a recipe, so it can be archived but not deleted."
    end
end
