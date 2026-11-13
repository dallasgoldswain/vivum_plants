# The collection and plant records (PL01–PL03, UX01, D80–D87).
class PlantsController < ApplicationController
  requires_capability "collection.plants"
  before_action :set_plant, only: %i[ show edit update ]

  def index
    authorize! Plant
    plants = authorized_scope(Plant.all)
    plants =
      if capability?("collection.search")
        plants.search(params[:q]).filtered(context: params[:context], status: params[:status], tc_origin: params[:tc], tag: params[:tag], environment: (params[:environment] if capability?("collection.environments")), unwatered_days: (params[:unwatered] if capability?("care.logs")))
      else
        plants.in_active_collection
      end
    @plants = plants.includes(cover_photo: { image_attachment: { blob: :variant_records } }).order(:display_name, :number)
    @last_watered = CareEvent.latest_by_plant(@plants.map(&:id), kinds: %w[ watering ]).transform_values { it["watering"] } if capability?("care.logs")
    @collection_size = Current.user.plants.count
    @view = params[:view] == "list" ? "list" : "grid"
    @environments = Current.user.environments.active.by_name if capability?("collection.environments")
  end

  def show
    ActiveRecord::Associations::Preloader.new(records: [ @plant ], associations: [ { environment_assignments: :environment }, { setups: { recipe_version: :recipe } } ]).call
    @timeline_kinds = @plant.care_events.distinct.pluck(:kind)
    @timeline_kinds << "maintenance" if capability?("care.shared_maintenance") && @plant.environment_event_plants.exists?
    @timeline_kind = params[:kind].presence_in(@timeline_kinds)
    @timeline = @plant.timeline(kind: @timeline_kind)
    load_care if capability?("care.logs")
    @schedules = @plant.care_schedules.where.not(status: "ended").includes(:open_task).order(:created_at) if capability?("care.reminders")
    @environments = Current.user.environments.active.by_name if capability?("collection.environments")
    @recipes = Current.user.recipes.active.includes(:versions).by_name if capability?("substrate.recipes")
    @photos = @plant.photos.with_attached_image.newest_first
    @quota = Photo.quota_for(Current.user)
  end

  def new
    authorize! Plant, to: :create?
    @plant = Current.user.plants.new
    @plant.build_acquisition
  end

  def create
    authorize! Plant, to: :create?
    @plant = Current.user.plants.new(plant_params)
    if @plant.save
      redirect_to @plant, notice: "#{@plant.display_name} added as #{@plant.record_id}."
    else
      @plant.build_acquisition unless @plant.acquisition
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @plant.build_acquisition unless @plant.acquisition
  end

  def update
    if @plant.update(plant_params)
      redirect_to @plant, notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_plant
      @plant = Current.user.plants.find(params[:id])
      authorize! @plant
    end

    # Quick care entry (D103): last care, the entry just saved, and earlier free text (D105).
    def load_care
      @last_care = @plant.last_care
      @logged_event = @plant.care_events.find_by(id: flash[:logged_care_event]) if flash[:logged_care_event]
      @care_suggestions = CareEvent.suggestions_for(Current.user)
    end

    def plant_params
      permitted = %i[ display_name botanical_name cultivar common_name nickname growing_context tc_origin origin_note quantity notes tag_list ]
      if capability?("collection.acquisition")
        permitted << { acquisition_attributes: %i[ id acquired_on source cost currency order_reference quantity arrival_notes ] }
      end
      params.expect(plant: permitted)
    end
end
