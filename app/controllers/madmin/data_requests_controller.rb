module Madmin
  class DataRequestsController < Madmin::ResourceController
    private
      # Whoever changes a request is recorded as handling it.
      def resource_params
        action_name == "update" ? super.merge(handled_by: Current.user) : super
      end
  end
end
