# A plant's reminders: add with a date preview and a duplicate check, edit, end (CA02, CA05,
# D112, D118, D120).
class Plants::CareSchedulesController < ApplicationController
  include PlantScoped
  include CareScheduleForm
  requires_capability "care.reminders"
  before_action :set_schedule, only: %i[ edit update destroy ]

  def new
    @schedule = default_schedule(@plant)
  end

  def create
    @schedule = @plant.care_schedules.new(user: Current.user, **schedule_attributes)
    return render(:new, status: :unprocessable_entity) unless @schedule.valid?

    @duplicates = @schedule.same_kind_for_plant
    return render(:duplicate) if @duplicates.any? && !params[:duplicate].in?(%w[ keep replace ])

    CareSchedule.transaction do
      @duplicates.each(&:end!) if params[:duplicate] == "replace"
      @schedule.save!
      @schedule.start!
    end
    redirect_to plant_path(@plant, anchor: "reminders"), notice: "Reminder set. Next: #{l(@schedule.open_task.due_on, format: :long)}."
  end

  def edit
  end

  def update
    CareSchedule.transaction do
      @schedule.update!(schedule_attributes.except(:kind))
      @schedule.reschedule_open_task!
    end
    redirect_to plant_path(@plant, anchor: "reminders"), notice: "Reminder saved."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  # Ending a reminder cancels its open task and keeps its history (D120).
  def destroy
    @schedule.end!
    redirect_to plant_path(@plant, anchor: "reminders"), notice: "Reminder ended. Its history stays on the timeline."
  end

  private
    def set_schedule
      @schedule = @plant.care_schedules.where.not(status: "ended").find(params[:id])
    end
end
