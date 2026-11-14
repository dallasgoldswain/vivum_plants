# The platform library (D153): published profiles every collector can read and copy. Drafts
# and retired versions are never shown (D141).
class PlatformProfilesController < ApplicationController
  requires_capability "library.profiles"

  def index
    authorize! LibraryProfile
    @profiles = LibraryProfile.published.includes(:published_version).search(params[:q]).covering(params[:context]).by_name
  end

  def show
    @profile = LibraryProfile.published.includes(:published_version).find(params[:id])
    authorize! @profile
    @copies = Current.user.library_profiles.matching(@profile.botanical_name).by_name
  end
end
