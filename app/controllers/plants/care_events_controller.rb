# Observations on the plant timeline (PL04, D82). Answers JSON for the offline queue (OF02,
# D84): the client's idempotency key means a retried or twice-synced entry saves once.
class Plants::CareEventsController < ApplicationController
  include PlantScoped

  def create
    key = event_params[:idempotency_key].to_s.first(64).presence || SecureRandom.uuid
    if (existing = Current.user.care_events.find_by(idempotency_key: key))
      return respond_saved(existing, [])
    end

    @care_event = Current.user.care_events.new(plant: @plant, idempotency_key: key, note: event_params[:note], occurred_at: occurred_at)
    rejected = attach_photos(@care_event)

    if @care_event.save
      respond_saved(@care_event, rejected)
    else
      errors = @care_event.errors.full_messages + rejected
      respond_to do |format|
        format.html { redirect_to @plant, alert: errors.to_sentence }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotUnique
    respond_saved(Current.user.care_events.find_by!(idempotency_key: key), [])
  end

  def destroy
    @plant.care_events.find(params[:id]).destroy!
    redirect_to @plant, notice: "Observation deleted."
  end

  private
    def event_params
      params.fetch(:care_event, {}).permit(:note, :occurred_at, :idempotency_key, photos: [])
    end

    def occurred_at
      Time.zone.parse(event_params[:occurred_at].to_s) || Time.current
    rescue ArgumentError
      Time.current
    end

    # Photos over the cap or in the wrong format are refused; the note still saves (OF03).
    def attach_photos(event)
      uploads = Array(event_params[:photos]).compact_blank
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

    def respond_saved(event, rejected)
      respond_to do |format|
        format.html do
          flash[:alert] = "Saved without some photos. #{rejected.to_sentence}" if rejected.any?
          redirect_to @plant, notice: "Observation saved."
        end
        format.json { render json: { id: event.id, rejected_photos: rejected }, status: :created }
      end
    end
end
