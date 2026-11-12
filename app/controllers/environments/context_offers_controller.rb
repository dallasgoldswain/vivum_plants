# Answers the growing-context offer for every plant here that hasn't answered it (D91).
class Environments::ContextOffersController < ApplicationController
  include EnvironmentScoped

  def update
    accept = params[:answer] == "change"
    offers = @environment.current_assignments.includes(:plant, :environment).select(&:context_offer?)
    offers.each { it.plant.answer_context_offer!(accept: accept) }
    message = accept ? "#{helpers.pluralize(offers.size, 'plant')} set to #{helpers.growing_context_label(@environment.suggested_context).downcase}." : "Growing contexts kept."
    redirect_to @environment, notice: message
  end
end
