# What a care entry form sends (CA01, D104): the kind, its optional details, when it
# happened and the client's idempotency key. Shared by single-plant and several-plant
# logging, so both read the form the same way.
module CareEntry
  extend ActiveSupport::Concern

  private
    def care_entry_params
      params.fetch(:care_event, {}).permit(:kind, :note, :occurred_at, :idempotency_key, *CareEvent::DETAIL_COLUMNS, photos: [])
    end

    # The kind asked for; observations need only the collection, other kinds need care logs.
    def care_entry_kind
      kind = care_entry_params[:kind].presence_in(CareEvent::KINDS - CareEvent::PLACEMENT_KINDS) || "observation"
      kind == "observation" || capability?("care.logs") ? kind : raise(ActiveRecord::RecordNotFound)
    end

    def care_entry_key
      care_entry_params[:idempotency_key].to_s.first(64).presence || SecureRandom.uuid
    end

    def care_entry_attributes
      care_entry_params.slice(:note, *CareEvent::DETAIL_COLUMNS).to_h.transform_values(&:presence).merge(kind: care_entry_kind, occurred_at: care_entry_time)
    end

    def care_entry_time
      Time.zone.parse(care_entry_params[:occurred_at].to_s) || Time.current
    rescue ArgumentError
      Time.current
    end
end
