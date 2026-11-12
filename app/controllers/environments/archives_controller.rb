# Archiving keeps an environment's history and hides it from pickers; restoring brings it
# back (D95).
class Environments::ArchivesController < ApplicationController
  include EnvironmentScoped

  def create
    @environment.archive!
    redirect_to @environment, notice: "#{@environment.name} archived. Its history is kept."
  rescue Environment::NotArchivable => error
    redirect_to @environment, alert: error.message
  end

  def destroy
    @environment.update!(status: "active")
    redirect_to @environment, notice: "#{@environment.name} restored."
  end
end
