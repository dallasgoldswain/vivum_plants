# Moving several plants into an environment with one date (EN03, D93).
class Environments::MovesController < ApplicationController
  include EnvironmentScoped

  def create
    ids = Array(params.dig(:move, :plant_ids)).compact_blank
    return redirect_to(@environment, alert: "Choose at least one plant.") if ids.empty?

    plants = Current.user.plants.where(id: ids).order(:display_name)
    on = date_param(params.dig(:move, :moved_on))
    moved, refused = [], []
    plants.each do |plant|
      plant.move_to!(@environment, on: on)
      moved << plant
    rescue Plant::Placement::MoveRefused => error
      refused << error.message
    end

    flash[:alert] = refused.to_sentence if refused.any?
    flash[:notice] = "#{helpers.pluralize(moved.size, 'plant')} moved into #{@environment.name}." if moved.any?
    redirect_to @environment
  end
end
