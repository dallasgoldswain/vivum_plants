# Links an unlinked alias to this buyer, by hand (D172).
class Sell::Buyers::AliasLinksController < Sell::BaseController
  include BuyerScoped

  def create
    buyer_alias = Current.seller.buyer_aliases.unlinked.find(params[:alias_id])
    buyer_alias.update!(buyer: @buyer)
    Audit.record("buyer_alias.linked", target: buyer_alias, details: { buyer_id: @buyer.id })
    back_to_buyer(notice: "#{buyer_alias.label} linked.")
  end
end
