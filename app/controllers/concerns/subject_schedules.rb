# Reminders on a plant's or an environment's page (CA02, CA05, D112, D118, D120, D125): add
# with a date preview and a duplicate check, edit, end. The including controller loads the
# plant or environment first and names it in `schedule_subject`.
module SubjectSchedules
  extend ActiveSupport::Concern

  included do
    include CareScheduleForm
    requires_capability "care.reminders"
    before_action { @subject = schedule_subject }
    before_action :set_schedule, only: %i[ edit update destroy ]
  end

  def new
    @schedule = default_schedule(@subject)
    render "schedules/new"
  end

  def create
    @schedule = @subject.care_schedules.new(user: Current.user, **schedule_attributes)
    return render("schedules/new", status: :unprocessable_entity) unless @schedule.valid?

    @duplicates = @schedule.same_kind_for_subject
    return render("schedules/duplicate") if @duplicates.any? && !params[:duplicate].in?(%w[ keep replace ])

    CareSchedule.transaction do
      @duplicates.each(&:end!) if params[:duplicate] == "replace"
      @schedule.save!
      @schedule.start!
    end
    redirect_to reminders_path, notice: "Reminder set. Next: #{l(@schedule.open_task.due_on, format: :long)}."
  end

  def edit
    render "schedules/edit"
  end

  def update
    CareSchedule.transaction do
      @schedule.update!(schedule_attributes.except(:kind))
      @schedule.reschedule_open_task!
    end
    redirect_to reminders_path, notice: "Reminder saved."
  rescue ActiveRecord::RecordInvalid
    render "schedules/edit", status: :unprocessable_entity
  end

  # Ending a reminder cancels its open task and keeps its history (D120).
  def destroy
    @schedule.end!
    redirect_to reminders_path, notice: "Reminder ended. Its history stays."
  end

  private
    def set_schedule
      @schedule = @subject.care_schedules.where.not(status: "ended").find(params[:id])
    end

    def reminders_path = polymorphic_path(@subject, anchor: "reminders")
end
