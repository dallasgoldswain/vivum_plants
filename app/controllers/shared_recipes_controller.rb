# A recipe's public link (D102): opens without signing in and shows the latest ready version
# with the scaler. Private notes and the plants that use it are never shown. The link stops
# working when the owner turns it off, archives the recipe, or loses the capability.
class SharedRecipesController < ApplicationController
  allow_unauthenticated_access
  skip_verify_authorized
  layout "public"

  def show
    @recipe = Recipe.active.find_by!(share_token: params[:token].to_s)
    @version = @recipe.latest_ready_version
    raise ActiveRecord::RecordNotFound unless @version && Capabilities.enabled?("substrate.share", user: @recipe.user)

    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    response.headers["Referrer-Policy"] = "no-referrer"
  end
end
