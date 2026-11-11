# The collection and plant records (PL01–PL03, UX01, D80–D87).
class PlantsController < ApplicationController
  requires_capability "collection.plants"
  before_action :set_plant, only: %i[ show edit update ]

  def index
    authorize! Plant
    plants = authorized_scope(Plant.all)
    plants =
      if capability?("collection.search")
        plants.search(params[:q]).filtered(context: params[:context], status: params[:status], tc_origin: params[:tc], tag: params[:tag])
      else
        plants.in_active_collection
      end
    @plants = plants.includes(cover_photo: { image_attachment: { blob: :variant_records } }).order(:display_name, :number)
    @collection_size = Current.user.plants.count
    @view = params[:view] == "list" ? "list" : "grid"
  end

  def show
    @timeline = @plant.timeline
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

    def plant_params
      permitted = %i[ display_name botanical_name cultivar common_name nickname growing_context tc_origin origin_note quantity notes tag_list ]
      if capability?("collection.acquisition")
        permitted << { acquisition_attributes: %i[ id acquired_on source cost currency order_reference quantity arrival_notes ] }
      end
      params.expect(plant: permitted)
    end
end
