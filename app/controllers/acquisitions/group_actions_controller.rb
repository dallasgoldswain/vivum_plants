# Acting on all or ticked plantlets of a TC purchase at once (D130): change stage, log a
# check, or mark lost. One entry per plantlet.
class Acquisitions::GroupActionsController < ApplicationController
  requires_capability "collection.tissue_culture"

  def create
    @acquisition = Current.user.acquisitions.purchase_groups.find(params[:acquisition_id])
    authorize! Plant, to: :index?
    plants = @acquisition.plants.in_active_collection.where(id: Array(params[:plant_ids])).order(:number).to_a
    return redirect_to(acquisition_path(@acquisition), alert: "Tick at least one plantlet.") if plants.empty?

    on = date_param(params[:on])
    case params[:group_action]
    when "stage" then change_stage(plants, on)
    when "check" then log_check(plants, on)
    when "lost" then mark_lost(plants, on)
    else redirect_to acquisition_path(@acquisition), alert: "Choose what to do."
    end
  rescue Plant::Placement::MoveRefused => error
    redirect_to acquisition_path(@acquisition), alert: error.message
  end

  private
    def change_stage(plants, on)
      stage = params[:stage].presence_in(Plant::TC_STAGES) or return redirect_to(acquisition_path(@acquisition), alert: "Choose a stage.")
      Plant.transaction { plants.each { it.change_stage!(stage, on: on) } }
      notice = "#{helpers.pluralize(plants.size, 'plantlet')} set to #{helpers.tc_stage_label(stage).downcase}."
      if capability?("care.reminders") && TissueCulture::Suggestions.for(stage, plants.first.growing_context).any?
        redirect_to new_tc_suggestion_path(plant_ids: plants.map(&:id), stage: stage), notice: notice
      elsif stage == "established" && plants.any? { it.open_tc_reminders.exists? }
        redirect_to acquisition_path(@acquisition), notice: "#{notice} Review each one's TC reminders on its page."
      else
        redirect_to acquisition_path(@acquisition), notice: notice
      end
    end

    def log_check(plants, on)
      check = params.fetch(:check, {}).permit(:note, :humidity_setup, *CareEvent::TC_CHECK_TICKS).to_h.symbolize_keys.transform_values(&:presence)
      key = params[:idempotency_key].to_s.first(48).presence || SecureRandom.uuid
      at = on == Date.current ? Time.current : on.in_time_zone.change(hour: 12)
      CareEvent.transaction do
        plants.each { |plant| CareEvent.record_once(user: Current.user, plant: plant, idempotency_key: "#{key}:#{plant.id}", kind: "inspection", occurred_at: at, **check).then { it.persisted? || raise(ActiveRecord::RecordInvalid, it) } }
      end
      redirect_to acquisition_path(@acquisition), notice: "Check logged for #{helpers.pluralize(plants.size, 'plantlet')}."
    end

    def mark_lost(plants, on)
      Plant.transaction { plants.each { it.change_status!("lost", on: on, reason: "Lost plantlet") } }
      redirect_to acquisition_path(@acquisition), notice: "#{helpers.pluralize(plants.size, 'plantlet')} marked lost. #{@acquisition.remaining} of #{@acquisition.quantity} remain."
    end
end
