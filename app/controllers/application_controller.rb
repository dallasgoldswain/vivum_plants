class ApplicationController < ActionController::Base
  include Authentication
  include CapabilityGating

  # Store ?ref=CODE in a cookie so a later sign-up can be credited (config/initializers/refer.rb).
  set_referral_cookie

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

  private
    # A date from a form, or today when it's missing or not a date.
    def date_param(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      Date.current
    end
end
