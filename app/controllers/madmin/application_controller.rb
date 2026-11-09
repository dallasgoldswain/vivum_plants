module Madmin
  # Only verified platform operators with two-step sign-in can use /madmin.
  # The Authentication concern enforces sign-in, email verification and
  # two-step enrolment (always required for operators).
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers
    include ::Authentication

    before_action :require_platform_operator

    private
      # 404 rather than 403 so the area's existence isn't revealed.
      def require_platform_operator
        raise ActionController::RoutingError, "Not Found" unless Current.user&.platform_operator?
      end
  end
end
