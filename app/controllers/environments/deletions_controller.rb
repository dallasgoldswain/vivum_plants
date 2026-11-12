# Permanent delete, only for an environment that has never held a plant (D95).
class Environments::DeletionsController < ApplicationController
  include EnvironmentScoped
  before_action :require_deletable

  def new
    @effects = @environment.deletion_effects
  end

  def create
    @environment.destroy!
    redirect_to environments_path, notice: "#{@environment.name} deleted."
  end

  private
    def require_deletable
      return if @environment.deletable?

      redirect_to @environment, alert: "#{@environment.name} has held plants, so it can be archived but not deleted. Archiving keeps its history."
    end
end
