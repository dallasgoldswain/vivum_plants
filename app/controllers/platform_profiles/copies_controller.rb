# Copies a published platform profile into your library to edit (D150). With a plant, the
# copy is linked to it as well (D151).
class PlatformProfiles::CopiesController < ApplicationController
  requires_capability "library.profiles"

  def create
    source = LibraryProfile.published.find(params[:platform_profile_id])
    authorize! source, to: :copy?
    copy = source.copy_for!(Current.user)
    redirect_to library_profile_path(copy), notice: "Copied to your library. Change what you need."
  end
end
