# Observations and logged care on the plant timeline (PL04, CA01, UX02, D82, D103–D108).
# Answers JSON for the offline queue (OF02, D84, D110): the client's idempotency key means a
# retried or twice-synced entry saves once.
class Plants::CareEventsController < ApplicationController
  include PlantScoped
  include CareEntry
  before_action :set_care_event, only: %i[ edit update destroy ]
  requires_capability "care.logs", only: %i[ edit update ]

  def create
    key = care_entry_key
    if (existing = Current.user.care_events.find_by(idempotency_key: key))
      return respond_saved(existing, [])
    end

    @care_event = Current.user.care_events.new(plant: @plant, idempotency_key: key, **care_entry_attributes)
    rejected = attach_photos(@care_event)

    if save_entry(@care_event)
      respond_saved(@care_event, rejected)
    else
      respond_refused(@care_event.errors.full_messages + rejected)
    end
  rescue ActiveRecord::RecordNotUnique
    respond_saved(Current.user.care_events.find_by!(idempotency_key: key), [])
  rescue ActiveRecord::RecordInvalid => error
    respond_refused(error.record.errors.full_messages)
  rescue Plant::Placement::MoveRefused => error
    respond_refused([ error.message ])
  end

  def edit
    @suggestions = CareEvent.suggestions_for(Current.user)
  end

  def update
    attributes = care_entry_params.slice(:note, *CareEvent::DETAIL_COLUMNS).to_h.transform_values(&:presence)
    attributes[:occurred_at] = care_entry_time if @care_event.date_editable? && care_entry_params[:occurred_at].present?
    if @care_event.update(attributes)
      redirect_to plant_path(@plant, anchor: "timeline"), notice: "Saved."
    else
      @suggestions = CareEvent.suggestions_for(Current.user)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    return redirect_to(@plant, alert: "This entry mirrors a move or setup change, so it stays.") unless @care_event.deletable?

    @care_event.destroy!
    redirect_to plant_path(@plant, anchor: "timeline"), notice: (@care_event.observation? ? "Observation deleted." : "Entry deleted.")
  end

  private
    def set_care_event
      @care_event = @plant.care_events.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @care_event.editable?
    end

    # A repot also writes the new setup when it has one (D106).
    def save_entry(event)
      return event.save unless event.repotting? && capability?("collection.environments")

      @plant.repot!(event, params.fetch(:setup, {}).permit(:container, :size, :size_unit, :recipe_version_id).to_h.transform_values(&:presence))
    end

    # Photos over the cap or in the wrong format are refused; the note still saves (OF03).
    def attach_photos(event)
      uploads = Array(care_entry_params[:photos]).compact_blank
      return [] if uploads.empty? || !capability?("collection.media")

      remaining = Photo.quota_for(Current.user).remaining
      uploads.each_with_object([]) do |upload, rejected|
        if remaining <= 0
          rejected << "#{upload.original_filename}: you've reached your #{Photo::COLLECTOR_LIMIT} photos."
          next
        end
        event.photos << Photo.build_from_upload(upload, user: Current.user, plant: @plant, care_event: event)
        event.photos_expected = true
        remaining -= 1
      rescue Photo::Rejected => error
        rejected << "#{upload.original_filename}: #{error.message}"
      end.uniq
    end

    # The plant page shows the saved entry with Undo and "Add details" (D103).
    def respond_saved(event, rejected)
      flash[:logged_care_event] = event.id unless event.observation?
      respond_to do |format|
        format.html do
          flash[:alert] = "Saved without some photos. #{rejected.to_sentence}" if rejected.any?
          redirect_to @plant, notice: (event.observation? ? "Observation saved." : nil)
        end
        format.json { render json: { id: event.id, rejected_photos: rejected }, status: :created }
      end
    end

    def respond_refused(errors)
      respond_to do |format|
        format.html { redirect_to @plant, alert: errors.to_sentence }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
end
