# Links a plant to a profile in your library, or copies a platform profile and links the
# copy (D151); unlinking keeps reminders and history.
class Plants::LibraryLinksController < ApplicationController
  include PlantScoped
  requires_capability "library.profiles"

  def create
    profile =
      if params[:platform_profile_id].present?
        source = LibraryProfile.published.find(params[:platform_profile_id])
        authorize! source, to: :copy?
        source.copy_for!(Current.user)
      else
        Current.user.library_profiles.find(params[:library_profile_id])
      end
    @plant.update!(library_profile: profile)
    redirect_to plant_path(@plant, anchor: "guidance"), notice: "Linked to your #{profile.botanical_name} profile."
  end

  def destroy
    @plant.update!(library_profile: nil)
    redirect_to plant_path(@plant, anchor: "guidance"), notice: "Unlinked. Its reminders stay as they are."
  end
end
