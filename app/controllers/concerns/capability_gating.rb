# Gates controller actions and views on Capabilities (PRD FF01).
#
#   class StockItemsController < ApplicationController
#     requires_capability "seller.stock"
#   end
#
# A disabled capability returns 404, so a hidden button's URL can't be used directly.
module CapabilityGating
  extend ActiveSupport::Concern

  included do
    helper_method :capability?
  end

  class_methods do
    def requires_capability(key, **options)
      before_action(**options) { raise ActionController::RoutingError, "Not Found" unless capability?(key) }
    end
  end

  private
    def capability?(key)
      Capabilities.enabled?(key, user: Current.user, seller: Current.seller)
    end
end
