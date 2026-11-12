# Loads the signed-in collector's own ingredient for nested ingredient controllers. A
# built-in or someone else's ingredient is a 404 (D87, D96).
module IngredientScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "substrate.ingredients"
    before_action :set_ingredient
  end

  private
    def set_ingredient
      @ingredient = Current.user.ingredients.find(params[:ingredient_id])
      authorize! @ingredient, to: :update?
    end
end
