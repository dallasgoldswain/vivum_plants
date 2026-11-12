# Dated readings of an environment's conditions (EN02, D90). Answers JSON for the offline
# queue (D94): the client's idempotency key means a retried or twice-synced reading saves once.
class Environments::MeasurementsController < ApplicationController
  include EnvironmentScoped
  requires_capability "collection.measurements"

  def create
    attributes = measurement_params
    key = attributes[:idempotency_key].to_s.first(64).presence || SecureRandom.uuid
    if (existing = Current.user.measurements.find_by(idempotency_key: key))
      return respond_saved(existing)
    end

    measurement = Current.user.measurements.new(environment: @environment, idempotency_key: key, measured_at: time_param(attributes[:measured_at]), source: attributes[:source], note: attributes[:note])
    measurement.assign_readings(fixed: attributes[:values], custom: attributes[:custom], new_custom: attributes[:new_custom]&.values)

    if measurement.save
      respond_saved(measurement)
    else
      errors = measurement.errors.full_messages
      respond_to do |format|
        format.html { redirect_to environment_path(@environment, anchor: "conditions"), alert: errors.to_sentence }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotUnique
    respond_saved(Current.user.measurements.find_by!(idempotency_key: key))
  end

  def destroy
    @environment.measurements.find(params[:id]).destroy!
    redirect_to environment_path(@environment, anchor: "conditions"), notice: "Reading deleted."
  end

  private
    def measurement_params
      params.fetch(:measurement, {}).permit(:idempotency_key, :measured_at, :source, :note, values: {}, custom: {}, new_custom: %i[ name unit value ])
    end

    def time_param(value)
      Time.zone.parse(value.to_s) || Time.current
    rescue ArgumentError
      Time.current
    end

    def respond_saved(measurement)
      respond_to do |format|
        format.html { redirect_to environment_path(@environment, anchor: "conditions"), notice: "Reading saved." }
        format.json { render json: { id: measurement.id }, status: :created }
      end
    end
end
