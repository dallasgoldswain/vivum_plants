# Changes one plant's guidance switches; no other plant or the defaults change (ST01, D139).
class Plants::GuidancesController < ApplicationController
  include PlantScoped
  requires_capability "care.guidance_settings"

  def update
    switches = { guidance_library: params[:library] == "1" }
    switches[:guidance_ai] = params[:ai] == "1" if capability?("care.ai_guidance")
    @plant.update!(switches)
    redirect_to plant_path(@plant, anchor: "guidance"), notice: "Guidance saved for #{@plant.display_name}."
  end
end
