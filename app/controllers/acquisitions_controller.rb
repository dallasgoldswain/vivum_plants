# Purchased tissue culture groups (TC01, D127): record a purchase as one record per plantlet,
# see arrival vs remaining, delete an empty group (D134).
class AcquisitionsController < ApplicationController
  requires_capability "collection.plants"
  requires_capability "collection.tissue_culture"
  before_action :set_acquisition, only: %i[ show destroy ]

  def new
    authorize! Plant, to: :create?
    @purchase = TissueCulture::Purchase.new(acquired_on: Date.current)
    load_environments
  end

  def create
    authorize! Plant, to: :create?
    @purchase = TissueCulture::Purchase.new(purchase_params.merge(user: Current.user))
    if @purchase.save
      attach_photos(@purchase.acquisition)
      redirect_to acquisition_path(@purchase.acquisition), notice: "#{helpers.pluralize(@purchase.quantity, 'plantlet')} recorded."
    else
      load_environments
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @plants = @acquisition.plants.includes(:current_environment, cover_photo: { image_attachment: :blob }).order(:number)
    @photos = @acquisition.photos.with_attached_image.newest_first
    @quota = Photo.quota_for(Current.user)
  end

  # Only an empty group can be deleted; its records go one by one, with their own warnings.
  def destroy
    return redirect_to(acquisition_path(@acquisition), alert: "Delete or keep its plantlets first.") if @acquisition.plants.exists?

    @acquisition.destroy!
    redirect_to plants_path, notice: "Purchase deleted."
  end

  private
    def set_acquisition
      @acquisition = Current.user.acquisitions.purchase_groups.find(params[:id])
      authorize! Plant, to: :index?
    end

    def purchase_params
      params.expect(tissue_culture_purchase: %i[ name botanical_name cultivar growing_context quantity stage source acquired_on deflasked_on container_condition cost currency order_reference arrival_notes environment_id ])
    end

    def load_environments
      @environments = Current.user.environments.active.by_name if capability?("collection.environments")
    end

    def attach_photos(acquisition)
      uploads = Array(params.dig(:tissue_culture_purchase, :photos)).compact_blank
      return if uploads.empty? || !capability?("collection.media")

      rejected = uploads.filter_map do |upload|
        Photo.build_from_upload(upload, user: Current.user, acquisition: acquisition, caption: "On arrival").save! && nil
      rescue Photo::Rejected => error
        "#{upload.original_filename}: #{error.message}"
      end
      flash[:alert] = "Saved without some photos. #{rejected.uniq.to_sentence}" if rejected.any?
    end
end
