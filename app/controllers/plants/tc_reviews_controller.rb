# Once established, each open TC reminder is kept, ended, or replaced with normal care (TC05,
# D132). Nothing is removed without a choice.
class Plants::TcReviewsController < ApplicationController
  include PlantScoped
  requires_capability "collection.tissue_culture"
  requires_capability "care.reminders"

  def new
    @schedules = @plant.open_tc_reminders.includes(:open_task).order(:created_at)
    redirect_to plant_path(@plant, anchor: "reminders") if @schedules.empty?
  end

  def create
    choices = params.fetch(:choices, {}).to_unsafe_h.slice(*@plant.open_tc_reminders.pluck(:id).map(&:to_s))
    return redirect_to(new_plant_tc_review_path(@plant), alert: "Choose keep, end or replace for each reminder.") if choices.size < @plant.open_tc_reminders.count

    replace = nil
    CareSchedule.transaction do
      @plant.open_tc_reminders.where(id: choices.keys).each do |schedule|
        case choices[schedule.id.to_s]
        when "keep" then schedule.update!(origin: nil)
        when "end" then schedule.end!
        when "replace" then (replace ||= schedule) && schedule.end!
        end
      end
    end
    return redirect_to(new_plant_care_schedule_path(@plant), notice: "Set up its normal care.") if replace

    redirect_to plant_path(@plant, anchor: "reminders"), notice: "Reminders reviewed."
  end
end
