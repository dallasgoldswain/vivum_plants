# Quick Claim and the waitlist (LS04, D214, D215). The host records a claim and offers
# returned stock to the next person waiting; owners and managers return or remove claims.
class Sell::SaleSessions::ClaimsController < Sell::BaseController
  include SaleSessionScoped
  requires_capability "sales.quick_claim"
  requires_capability "sales.waitlist", only: :offer
  before_action :set_claim, except: :create
  before_action(only: %i[ create offer ]) { authorize! @sale_session, to: :host? }
  before_action(except: %i[ create offer ]) { authorize! @sale_session, to: :update? }

  def create
    claim_item = @sale_session.claim_items.find(params[:claim_item_id])
    claim = claim_item.claim!(member: Current.user, holder: holder(:claimer), quantity: params[:quantity].presence || 1, message_reference: params[:message_reference], waitlist: capability?("sales.waitlist"))
    back(notice: claim.held? ? "#{claim.quantity} held for #{claim.holder_name}." : "#{claim.holder_name} is ##{claim.position} on the waitlist.")
  end

  def offer
    @claim.offer!(member: Current.user)
    back(notice: "#{@claim.quantity} held for #{@claim.holder_name}.")
  end

  def return_stock
    @claim.return_to_stock!(member: Current.user)
    back(notice: "#{@claim.holder_name}'s claim returned to stock.")
  end

  def remove
    @claim.remove!(member: Current.user)
    back(notice: "#{@claim.holder_name} is off the waitlist.")
  end

  private
    def set_claim
      @claim = SaleClaim.where(claim_item: @sale_session.claim_items).find(params[:id])
    end
end
