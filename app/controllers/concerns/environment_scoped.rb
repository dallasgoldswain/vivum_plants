# Loads the signed-in collector's environment for nested environment controllers. Someone
# else's environment is a 404, never a 403 (D87).
module EnvironmentScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "collection.environments"
    before_action :set_environment
  end

  private
    def set_environment
      @environment = Current.user.environments.find(params[:environment_id])
      authorize! @environment, to: :update?
    end
end
