module Madmin
  # The platform library (D141, D142): operators add profiles and publish them through
  # versions. Every view and change is audited.
  class LibraryProfilesController < Madmin::ApplicationController
    helper ::PlantsHelper, ::CareHelper, ::LibraryHelper

    def index
      @profiles = LibraryProfile.platform.includes(:versions).search(params[:q]).by_name
      Audit.record("madmin.index", target_key: "LibraryProfile")
    end

    def show
      @profile = LibraryProfile.platform.find(params[:id])
      Audit.record("madmin.show", target: @profile)
    end

    def new
      @version = LibraryProfileVersion.new
    end

    # A new profile starts with version 1 as a draft.
    def create
      @profile = LibraryProfile.new(key: params[:key].to_s.strip.presence)
      @version = @profile.versions.new(version_params)
      @profile.botanical_name = @version.botanical_name
      LibraryProfile.transaction { @profile.save! }
      Audit.record("library.profile_created", target: @profile, details: { key: @profile.key })
      redirect_to madmin_library_profile_path(@profile), notice: "Profile created with a draft version."
    rescue ActiveRecord::RecordInvalid
      @version.errors.merge!(@profile.errors) if @profile.errors.any?
      render :new, status: :unprocessable_entity
    end

    private
      def version_params
        form = params.fetch(:library_profile_version, {})
        params.expect(library_profile_version: %i[ botanical_name synonym_list common_name_list family reviewed_on ])
          .merge(content_params: form.fetch(:content_params, {}).to_unsafe_h, reference_params: form.fetch(:reference_params, {}).to_unsafe_h)
      end
  end
end
