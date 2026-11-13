# Pausing a plant's or environment's reminder by hand, and resuming it from today (D119,
# D125). An inactive plant or archived environment keeps its reminders paused.
module SubjectSchedulePausing
  extend ActiveSupport::Concern

  included do
    requires_capability "care.reminders"
  end

  def create
    schedule.pause!
    redirect_to polymorphic_path(schedule_subject, anchor: "reminders"), notice: "Reminder paused."
  end

  def destroy
    unless resumable?
      return redirect_to(polymorphic_path(schedule_subject, anchor: "reminders"), alert: "#{helpers.subject_name(schedule_subject)} isn't active, so its reminders stay paused.")
    end

    schedule.resume!
    redirect_to polymorphic_path(schedule_subject, anchor: "reminders"), notice: "Reminder resumed. Next: #{l(schedule.open_task.due_on, format: :long)}."
  end

  private
    def schedule
      @schedule ||= schedule_subject.care_schedules.where.not(status: "ended").find(params[:care_schedule_id])
    end

    def resumable? = schedule_subject.active?
end
