# Environments: rooms, shelves, cabinets, tanks and beds, with their current plants, latest
# conditions and history (EN01–EN03, D88–D95).
class EnvironmentsController < ApplicationController
  requires_capability "collection.environments"
  before_action :set_environment, only: %i[ show edit update ]

  def index
    authorize! Environment
    @show_archived = params[:archived] == "1"
    @environments = authorized_scope(Environment.all).where(status: @show_archived ? "archived" : "active")
      .includes(:current_plants, cover_photo: { image_attachment: { blob: :variant_records } }).by_name
    @archived_count = Current.user.environments.archived.count
    @latest_readings = Measurement.where(environment: @environments).group(:environment_id).maximum(:measured_at)
  end

  def show
    @occupants = @environment.current_assignments.includes(plant: { cover_photo: { image_attachment: :blob } }).sort_by { it.plant.display_name.downcase }
    @history = @environment.assignments.includes(:plant).where.not(ended_on: nil).order(ended_on: :desc, id: :desc)
    @movable_plants = Current.user.plants.in_active_collection.where.not(id: @occupants.map(&:plant_id)).includes(current_assignment: :environment).order(:display_name, :number)
    @context_offers = @occupants.select(&:context_offer?)
    if capability?("collection.measurements")
      @latest_values = @environment.latest_values
      @measurements = @environment.measurements.newest_first.includes(values: :custom_metric).limit(30)
      @metrics = Measurement.metrics_for(@environment)
      @custom_metrics = Current.user.custom_metrics.by_name
    end
    @photos = @environment.photos.with_attached_image.newest_first
    @quota = Photo.quota_for(Current.user)
    load_maintenance if capability?("care.shared_maintenance")
    @schedules = @environment.care_schedules.where.not(status: "ended").includes(:open_task).order(:created_at) if capability?("care.reminders")
  end

  def new
    authorize! Environment, to: :create?
    @environment = Current.user.environments.new
  end

  def create
    authorize! Environment, to: :create?
    @environment = Current.user.environments.new(environment_params)
    if @environment.save
      redirect_to @environment, notice: "#{@environment.name} added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @environment.update(environment_params)
      redirect_to @environment, notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_environment
      @environment = Current.user.environments.find(params[:id])
      authorize! @environment
    end

    # Maintenance history with a kind filter, and the entry just saved (D122, D126).
    def load_maintenance
      events = @environment.maintenance_events
      @maintenance_kinds = events.distinct.pluck(:kind).sort_by { EnvironmentEvent::KINDS.index(it) }
      @maintenance_kind = params[:maintenance_kind].presence_in(@maintenance_kinds)
      @maintenance_events = events.includes(:plants, photos: { image_attachment: :blob }).newest_first.limit(30)
      @maintenance_events = @maintenance_events.where(kind: @maintenance_kind) if @maintenance_kind
      @logged_maintenance = events.find_by(id: flash[:logged_environment_event]) if flash[:logged_environment_event]
      @maintenance_suggestions = EnvironmentEvent.suggestions_for(Current.user)
    end

    def environment_params
      params.expect(environment: %i[ name kind notes length_cm width_cm height_cm volume_litres ])
    end
end
