# Answers the offer to match the growing context to the plant's environment (D91).
class Plants::ContextOffersController < ApplicationController
  include PlantScoped
  requires_capability "collection.environments"

  def update
    accept = params[:answer] == "change"
    @plant.answer_context_offer!(accept: accept)
    message = accept ? "Growing context set to #{helpers.growing_context_label(@plant.growing_context).downcase}." : "Growing context kept as #{helpers.growing_context_label(@plant.growing_context).downcase}."
    redirect_to plant_path(@plant, anchor: "placement"), notice: message
  end
end
