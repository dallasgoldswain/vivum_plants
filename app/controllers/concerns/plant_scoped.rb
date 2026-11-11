# Loads the signed-in collector's plant for nested plant controllers. Someone else's plant
# is a 404, never a 403 (D87).
module PlantScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "collection.plants"
    before_action :set_plant
  end

  private
    def set_plant
      @plant = Current.user.plants.find(params[:plant_id])
      authorize! @plant, to: :update?
    end
end
