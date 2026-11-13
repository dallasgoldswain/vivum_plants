# Loads the signed-in collector's reminder task for the Today actions (CA03). Someone else's
# task is a 404 (D87).
module CareTaskScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "care.reminders"
    before_action :set_care_task
  end

  private
    def set_care_task
      @care_task = Current.user.care_tasks.includes(:plant, :environment, :care_schedule).find(params[:care_task_id] || params[:id])
      authorize! @care_task.subject, to: :update?
    end

    # Today answers JSON for the offline queue (D120), and HTML otherwise.
    def respond_done(notice, back: root_path)
      respond_to do |format|
        format.html { redirect_to back, notice: notice }
        format.json do
          flash[:notice] = notice
          render json: { ok: true }, status: :created
        end
      end
    end

    def respond_refused(errors, back: root_path)
      respond_to do |format|
        format.html { redirect_to back, alert: errors.to_sentence }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
end
