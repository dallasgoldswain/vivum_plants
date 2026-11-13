# Maintenance of an environment, such as a water change (EN04, D121–D124, D126). Answers JSON
# for the offline queue: the client's idempotency key means a retry saves once.
class Environments::MaintenanceEventsController < ApplicationController
  include EnvironmentScoped
  requires_capability "care.shared_maintenance"
  before_action :set_event, only: %i[ edit update destroy ]

  def create
    key = event_params[:idempotency_key].to_s.first(64).presence || SecureRandom.uuid
    if (existing = Current.user.environment_events.find_by(idempotency_key: key))
      return respond_saved(existing, [])
    end

    @event = Current.user.environment_events.new(environment: @environment, idempotency_key: key, **event_attributes, kind: event_params[:kind], occurred_at: occurred_at)
    rejected = attach_photos(@event)
    if @event.save
      respond_saved(@event, rejected)
    else
      respond_refused(@event.errors.full_messages + rejected)
    end
  rescue ActiveRecord::RecordNotUnique
    respond_saved(Current.user.environment_events.find_by!(idempotency_key: key), [])
  end

  def edit
    @suggestions = EnvironmentEvent.suggestions_for(Current.user)
  end

  def update
    attributes = event_attributes
    attributes[:occurred_at] = occurred_at if event_params[:occurred_at].present?
    if @event.update(attributes)
      redirect_to environment_path(@environment, anchor: "maintenance"), notice: "Saved."
    else
      @suggestions = EnvironmentEvent.suggestions_for(Current.user)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_to environment_path(@environment, anchor: "maintenance"), notice: "Entry deleted."
  end

  private
    def set_event
      @event = @environment.maintenance_events.find(params[:id])
    end

    def event_params
      params.fetch(:environment_event, {}).permit(:kind, :note, :occurred_at, :idempotency_key, *EnvironmentEvent::DETAIL_COLUMNS, photos: [])
    end

    def event_attributes
      event_params.slice(:note, *EnvironmentEvent::DETAIL_COLUMNS).to_h.symbolize_keys.transform_values(&:presence)
    end

    def occurred_at
      Time.zone.parse(event_params[:occurred_at].to_s) || Time.current
    rescue ArgumentError
      Time.current
    end

    # Photos over the cap or in the wrong format are refused; the entry still saves (OF03).
    def attach_photos(event)
      uploads = Array(event_params[:photos]).compact_blank
      return [] if uploads.empty? || !capability?("collection.media")

      remaining = Photo.quota_for(Current.user).remaining
      uploads.each_with_object([]) do |upload, rejected|
        if remaining <= 0
          rejected << "#{upload.original_filename}: you've reached your #{Photo::COLLECTOR_LIMIT} photos."
          next
        end
        event.photos << Photo.build_from_upload(upload, user: Current.user, environment: @environment, environment_event: event)
        remaining -= 1
      rescue Photo::Rejected => error
        rejected << "#{upload.original_filename}: #{error.message}"
      end.uniq
    end

    # The environment page shows the saved entry with Undo and "Add details" (D122).
    def respond_saved(event, rejected)
      flash[:logged_environment_event] = event.id
      respond_to do |format|
        format.html do
          flash[:alert] = "Saved without some photos. #{rejected.to_sentence}" if rejected.any?
          redirect_to environment_path(@environment, anchor: "maintenance")
        end
        format.json { render json: { id: event.id, rejected_photos: rejected }, status: :created }
      end
    end

    def respond_refused(errors)
      respond_to do |format|
        format.html { redirect_to environment_path(@environment, anchor: "maintenance"), alert: errors.to_sentence }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
end
