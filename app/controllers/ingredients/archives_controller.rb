# Archiving hides an ingredient from recipe pickers and keeps the recipes that use it (D101).
class Ingredients::ArchivesController < ApplicationController
  include IngredientScoped

  def create
    @ingredient.update!(status: "archived")
    redirect_to @ingredient, notice: "#{@ingredient.label} archived."
  end

  def destroy
    @ingredient.update!(status: "active")
    redirect_to @ingredient, notice: "#{@ingredient.label} restored."
  end
end
