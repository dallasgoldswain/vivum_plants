# Moving a plant into another environment, or out of its current one (EN03, D93).
class Plants::MovesController < ApplicationController
  include PlantScoped
  requires_capability "collection.environments"

  def create
    attributes = params.fetch(:move, {}).permit(:environment_id, :moved_on)
    environment = Current.user.environments.find(attributes[:environment_id]) if attributes[:environment_id].present?
    @plant.move_to!(environment, on: date_param(attributes[:moved_on]))
    redirect_to plant_path(@plant, anchor: "placement"), notice: environment ? "Moved into #{environment.name}." : "Taken out of its environment."
  rescue Plant::Placement::MoveRefused => error
    redirect_to plant_path(@plant, anchor: "placement"), alert: error.message
  end
end
