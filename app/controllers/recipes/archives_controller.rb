# Archiving hides a recipe from the setup picker and keeps every version and the plants that
# used them (D101).
class Recipes::ArchivesController < ApplicationController
  include RecipeScoped

  def create
    @recipe.update!(status: "archived")
    redirect_to @recipe, notice: "#{@recipe.name} archived. Its versions and history are kept."
  end

  def destroy
    @recipe.update!(status: "active")
    redirect_to @recipe, notice: "#{@recipe.name} restored."
  end
end
