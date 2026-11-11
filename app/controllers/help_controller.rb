# The public product manual (HM01, D75): search and topics live for the viewer.
class HelpController < ApplicationController
  allow_unauthenticated_access
  skip_verify_authorized
  before_action :resume_session
  requires_capability "help.manual"

  def index
    @query = params[:q].to_s.strip.first(100)
    if @query.present?
      @results = HelpTopic.search(@query, user: Current.user, seller: Current.seller)
    else
      @topics = HelpTopic.visible_to(user: Current.user, seller: Current.seller).group_by(&:audience)
    end
  end

  # A topic for a capability that's off for the viewer doesn't exist for them.
  def show
    @topic = HelpTopic.find(params[:id])
    raise ActionController::RoutingError, "Not Found" unless @topic.visible_to?(user: Current.user, seller: Current.seller)
  rescue HelpTopic::NotFound
    raise ActionController::RoutingError, "Not Found"
  end
end
