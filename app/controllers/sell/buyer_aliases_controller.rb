# Aliases (BY02, D172): any member adds one; owners and managers link it to a buyer, unlink,
# or remove it. Matching names are never linked automatically.
class Sell::BuyerAliasesController < Sell::BaseController
  requires_capability "seller.buyers"
  before_action :set_alias, only: %i[ update destroy ]

  def create
    authorize! BuyerAlias
    buyer_alias = Current.seller.buyer_aliases.new(params.expect(buyer_alias: %i[ name group_name ]).merge(created_by: Current.user))
    if buyer_alias.save
      back(notice: "Alias #{buyer_alias.label} added.")
    else
      back(alert: buyer_alias.errors.full_messages.to_sentence)
    end
  end

  def update
    buyer = Current.seller.buyers.active.find(params[:buyer_id]) if params[:buyer_id].present?
    @alias.update!(buyer: buyer)
    Audit.record(buyer ? "buyer_alias.linked" : "buyer_alias.unlinked", target: @alias, details: { buyer_id: buyer&.id })
    back(notice: buyer ? "#{@alias.label} linked to #{buyer.name}." : "#{@alias.label} unlinked.")
  end

  def destroy
    @alias.destroy!
    back(notice: "Alias removed.")
  end

  private
    def set_alias
      @alias = authorized_scope(BuyerAlias.all).find(params[:id])
      authorize! @alias
    end

    def back(**flash) = redirect_back_or_to(sell_buyers_path, **flash)
end
