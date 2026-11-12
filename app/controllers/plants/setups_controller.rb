# A new pot, size or watering method from a date on (PL05, D89).
class Plants::SetupsController < ApplicationController
  include PlantScoped
  requires_capability "collection.environments"

  def create
    attributes = params.expect(plant_setup: %i[ container size size_unit watering_method started_on ])
    @plant.change_setup!(attributes.except(:started_on).to_h.transform_values(&:presence), on: date_param(attributes[:started_on]))
    redirect_to plant_path(@plant, anchor: "placement"), notice: "Setup saved."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to plant_path(@plant, anchor: "placement"), alert: error.record.errors.full_messages.to_sentence
  rescue Plant::Placement::MoveRefused => error
    redirect_to plant_path(@plant, anchor: "placement"), alert: error.message
  end
end
