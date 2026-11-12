# Loads the signed-in collector's recipe for nested recipe controllers. Someone else's
# recipe is a 404, never a 403 (D87).
module RecipeScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "substrate.recipes"
    before_action :set_recipe
  end

  private
    def set_recipe
      @recipe = Current.user.recipes.find(params[:recipe_id])
      authorize! @recipe, to: :update?
    end
end
