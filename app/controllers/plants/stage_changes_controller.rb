# Changing a TC plant's stage from a date (TC02, D128). Answers JSON for the offline queue
# (D134). Afterwards it offers the stage's suggested reminders (D131), or, once established,
# the review of open TC reminders (D132).
class Plants::StageChangesController < ApplicationController
  include PlantScoped
  requires_capability "collection.tissue_culture"

  def create
    stage = params[:stage].presence_in(Plant::TC_STAGES) or return refuse("Choose a stage.")
    @plant.change_stage!(stage, on: date_param(params[:on]), idempotency_key: params[:idempotency_key].to_s.first(64).presence || SecureRandom.uuid)
    location = next_step(stage)
    respond_to do |format|
      format.html { redirect_to location, notice: "Stage set to #{helpers.tc_stage_label(stage).downcase}." }
      format.json do
        flash[:notice] = "Stage set to #{helpers.tc_stage_label(stage).downcase}."
        render json: { location: location }, status: :created
      end
    end
  rescue Plant::Placement::MoveRefused => error
    refuse(error.message)
  end

  private
    def next_step(stage)
      if stage == "established" && @plant.open_tc_reminders.exists?
        new_plant_tc_review_path(@plant)
      elsif capability?("care.reminders") && TissueCulture::Suggestions.for(stage, @plant.growing_context).any?
        new_tc_suggestion_path(plant_ids: [ @plant.id ], stage: stage)
      else
        plant_path(@plant, anchor: "tissue-culture")
      end
    end

    def refuse(message)
      respond_to do |format|
        format.html { redirect_to plant_path(@plant, anchor: "tissue-culture"), alert: message }
        format.json { render json: { errors: [ message ] }, status: :unprocessable_entity }
      end
    end
end
