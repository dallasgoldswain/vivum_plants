# Done on Today, for one task or a group (D113, D115): each task logs its own care, keyed from
# the form's idempotency key, so a retry or second offline sync logs nothing more (OF02).
class TaskCompletionsController < ApplicationController
  requires_capability "care.reminders"

  def create
    authorize! Plant, to: :index?
    tasks = Current.user.care_tasks.includes(:plant, :care_schedule).where(id: Array(params[:task_ids]).compact_blank).order(:due_on, :id).to_a
    return refuse("Tick at least one plant.") if tasks.empty?

    key = params[:idempotency_key].to_s.first(48).presence || SecureRandom.uuid
    CareTask.transaction { tasks.each { it.complete!(idempotency_key: "#{key}:#{it.id}") } }
    notice = "#{helpers.care_task_title(tasks.first)}: done for #{helpers.pluralize(tasks.size, 'plant')}."
    respond_to do |format|
      format.html { redirect_to root_path, notice: notice }
      format.json do
        flash[:notice] = notice
        render json: { count: tasks.size }, status: :created
      end
    end
  end

  private
    def refuse(message)
      respond_to do |format|
        format.html { redirect_to root_path, alert: message }
        format.json { render json: { errors: [ message ] }, status: :unprocessable_entity }
      end
    end
end
