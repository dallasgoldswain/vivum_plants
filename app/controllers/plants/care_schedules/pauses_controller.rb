# Pausing a reminder by hand, and resuming it from today (D119).
class Plants::CareSchedules::PausesController < ApplicationController
  include PlantScoped
  requires_capability "care.reminders"

  def create
    schedule.pause!
    redirect_to plant_path(@plant, anchor: "reminders"), notice: "Reminder paused."
  end

  def destroy
    return redirect_to(plant_path(@plant, anchor: "reminders"), alert: "#{@plant.display_name} isn't active, so its reminders stay paused.") unless @plant.active?

    schedule.resume!
    redirect_to plant_path(@plant, anchor: "reminders"), notice: "Reminder resumed. Next: #{l(schedule.open_task.due_on, format: :long)}."
  end

  private
    def schedule
      @schedule ||= @plant.care_schedules.where.not(status: "ended").find(params[:care_schedule_id])
    end
end
