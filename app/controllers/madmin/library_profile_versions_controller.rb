module Madmin
  # Versions of a platform profile (D141): drafts and versions in review can be edited;
  # publishing replaces the published version and mirrors it for collectors; published and
  # retired versions are never edited.
  class LibraryProfileVersionsController < Madmin::ApplicationController
    helper ::PlantsHelper, ::CareHelper, ::LibraryHelper

    before_action :set_profile
    before_action :set_version, except: %i[ new create ]

    def new
      @version = (@profile.versions.last || @profile.versions.new).then { it.persisted? ? it.next_draft : it }
    end

    def create
      @version = @profile.versions.new(version_params)
      if @version.save
        Audit.record("library.version_created", target: @version, details: { profile: @profile.id, number: @version.number })
        redirect_to madmin_library_profile_path(@profile), notice: "Version #{@version.number} saved as a draft."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      redirect_to madmin_library_profile_path(@profile), alert: "Published and retired versions can't be changed." unless @version.editable?
    end

    def update
      return redirect_to(madmin_library_profile_path(@profile), alert: "Published and retired versions can't be changed.") unless @version.editable?

      if @version.update(version_params)
        Audit.record("library.version_updated", target: @version, details: { changed_fields: @version.saved_changes.keys - %w[ updated_at ] })
        redirect_to madmin_library_profile_path(@profile), notice: "Version #{@version.number} saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def submit = transition(:submit!, "library.version_submitted", "sent to review", -> { @version.draft? })
    def back_to_draft = transition(:back_to_draft!, "library.version_returned", "back to draft", -> { @version.in_review? })
    def retire = transition(:retire!, "library.version_retired", "retired", -> { @version.published? })

    def publish
      return redirect_to(madmin_library_profile_path(@profile), alert: "Only a version in review can be published.") unless @version.in_review?

      @version.publish!(by: Current.user)
      Audit.record("library.version_published", target: @version, details: { profile: @profile.id, number: @version.number })
      redirect_to madmin_library_profile_path(@profile), notice: "Version #{@version.number} published. Collectors see it now; their copies don't change."
    end

    private
      def set_profile = @profile = LibraryProfile.platform.find(params[:library_profile_id])
      def set_version = @version = @profile.versions.find(params[:id])

      def transition(method, action, done, allowed)
        return redirect_to(madmin_library_profile_path(@profile), alert: "That step isn't available for this version.") unless allowed.call

        @version.public_send(method)
        Audit.record(action, target: @version, details: { profile: @profile.id, number: @version.number })
        redirect_to madmin_library_profile_path(@profile), notice: "Version #{@version.number} #{done}."
      end

      def version_params
        form = params.fetch(:library_profile_version, {})
        params.expect(library_profile_version: %i[ botanical_name synonym_list common_name_list family reviewed_on ])
          .merge(content_params: form.fetch(:content_params, {}).to_unsafe_h, reference_params: form.fetch(:reference_params, {}).to_unsafe_h)
      end
  end
end
