class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Every action must call authorize! (or explicitly opt out with skip_verify_authorized).
  authorize :membership, through: -> { Current.membership }
  verify_authorized

  rescue_from ActionPolicy::Unauthorized do
    respond_to do |format|
      format.html { redirect_back_or_to root_path, alert: "You don't have access to that." }
      format.any { head :forbidden }
    end
  end
end
