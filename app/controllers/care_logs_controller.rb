# One care entry for several plants at once, from an environment or the collection (D107).
# Each plant gets its own event, keyed from the form's idempotency key, so a retry or a
# second offline sync creates nothing more (OF02).
class CareLogsController < ApplicationController
  include CareEntry
  requires_capability "collection.plants"
  requires_capability "care.logs"

  # Repots set up each plant on its own (D106), so they're logged per plant.
  KINDS = CareEvent::LOGGED_KINDS - %w[ repotting ]

  def new
    authorize! Plant, to: :index?
    @environment = Current.user.environments.find(params[:environment_id]) if params[:environment_id].present?
    @plants = choosable_plants
    @selected = @environment ? @plants.map(&:id) : Array(params[:plant_ids]).map(&:to_i)
    @kind = params[:kind].presence_in(KINDS) || "watering"
    @suggestions = CareEvent.suggestions_for(Current.user)
  end

  def create
    authorize! Plant, to: :index?
    plants = authorized_scope(Plant.all).where(id: Array(params[:plant_ids]).compact_blank).order(:display_name).to_a
    return refuse([ "Choose at least one plant." ]) if plants.empty?
    return refuse([ "Choose what you did." ]) unless KINDS.include?(care_entry_kind)

    key = care_entry_key
    attributes = care_entry_attributes
    events = CareEvent.transaction do
      plants.map do |plant|
        plant_key = "#{key.first(48)}:#{plant.id}"
        Current.user.care_events.find_by(idempotency_key: plant_key) ||
          Current.user.care_events.create!(plant: plant, idempotency_key: plant_key, **attributes)
      end
    end
    respond_saved(events)
  rescue ActiveRecord::RecordNotUnique
    respond_saved(plants)
  rescue ActiveRecord::RecordInvalid => error
    refuse(error.record.errors.full_messages)
  end

  private
    def choosable_plants
      plants = authorized_scope(Plant.all).in_active_collection.order(:display_name, :number)
      return plants.where(id: EnvironmentAssignment.current.where(environment: @environment).select(:plant_id)) if @environment

      plants.search(params[:q]).filtered(context: params[:context], status: params[:status], tc_origin: params[:tc], tag: params[:tag], environment: params[:environment], unwatered_days: params[:unwatered])
    end

    def respond_saved(saved)
      notice = "Logged for #{helpers.pluralize(saved.size, 'plant')}."
      respond_to do |format|
        format.html { redirect_to return_path, notice: notice }
        format.json do
          flash[:notice] = notice
          render json: { count: saved.size }, status: :created
        end
      end
    end

    def refuse(errors)
      respond_to do |format|
        format.html { redirect_to new_care_log_path(environment_id: params[:environment_id], plant_ids: params[:plant_ids]), alert: errors.to_sentence }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end

    def return_path
      environment = Current.user.environments.find_by(id: params[:environment_id]) if params[:environment_id].present?
      environment ? environment_path(environment) : plants_path
    end
end
