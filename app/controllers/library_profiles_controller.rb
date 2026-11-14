# Your library (D149–D153): profiles you copied from the platform or started yourself, which
# your plants link to. Edits never change accepted reminders; linked plants are offered a
# review instead (D152).
class LibraryProfilesController < ApplicationController
  requires_capability "library.profiles"
  before_action :set_profile, only: %i[ show edit update destroy ]

  def index
    authorize! LibraryProfile
    profiles = authorized_scope(LibraryProfile.all).search(params[:q]).covering(params[:context])
    @profiles = profiles.by_name
    @platform_count = LibraryProfile.published.count
  end

  def show
    @plants = @profile.plants.order(:display_name, :number)
  end

  def new
    authorize! LibraryProfile, to: :create?
    @profile = Current.user.library_profiles.new(botanical_name: params[:botanical_name])
  end

  def create
    authorize! LibraryProfile, to: :create?
    @profile = Current.user.library_profiles.new(profile_params)
    if @profile.save
      redirect_to library_profile_path(@profile), notice: "#{@profile.botanical_name} added to your library."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to library_profile_path(@profile), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Only a profile no plant links to can be deleted.
  def destroy
    if @profile.plants.exists?
      redirect_to library_profile_path(@profile), alert: "Unlink its plants first."
    else
      @profile.destroy!
      redirect_to library_profiles_path, notice: "#{@profile.botanical_name} deleted from your library."
    end
  end

  private
    def set_profile
      @profile = Current.user.library_profiles.find(params[:id])
      authorize! @profile
    end

    # The content setters keep only known contexts, note fields and reminder columns.
    def profile_params
      form = params.fetch(:library_profile, {})
      params.expect(library_profile: %i[ botanical_name synonym_list common_name_list family ])
        .merge(content_params: form.fetch(:content_params, {}).to_unsafe_h, reference_params: form.fetch(:reference_params, {}).to_unsafe_h)
    end
end
