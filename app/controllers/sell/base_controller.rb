# The Sell area: only for members of a seller business (SO03), acting for one of them.
class Sell::BaseController < ApplicationController
  requires_capability "seller.workspace"
  before_action :require_membership

  private
    def require_membership
      return if Current.membership

      raise ActionController::RoutingError, "Not Found" unless Current.user.memberships.exists?

      redirect_to root_path, alert: "Choose which business to work as."
    end
end
