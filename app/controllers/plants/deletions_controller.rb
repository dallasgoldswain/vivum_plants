# Permanent deletion, after a warning that lists what goes (D86). Archiving is the routine path.
class Plants::DeletionsController < ApplicationController
  include PlantScoped

  def new
    @effects = @plant.deletion_effects
  end

  def create
    @plant.destroy!
    redirect_to plants_path, notice: "#{@plant.display_name} (#{@plant.record_id}) deleted."
  end
end
