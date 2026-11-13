# Applies the current defaults to one plant, after its comparison (ST04, D140). Only the
# switches and their revision change; reminders and history stay.
class Plants::GuidanceApplicationsController < ApplicationController
  include PlantScoped
  requires_capability "care.guidance_settings"

  def create
    @plant.apply_guidance_defaults!(Current.user.guidance_defaults)
    redirect_to plant_path(@plant, anchor: "guidance"), notice: "Applied your current defaults to #{@plant.display_name}."
  end
end
