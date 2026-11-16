# Merges another buyer into this one (D178), by hand only.
class Sell::Buyers::MergesController < Sell::BaseController
  include BuyerScoped

  def create
    other = Current.seller.buyers.active.find(params[:other_buyer_id])
    authorize! other, to: :merge?
    name = other.name
    @buyer.merge!(other)
    back_to_buyer(notice: "#{name} merged into #{@buyer.name}.")
  rescue ArgumentError => error
    back_to_buyer(alert: error.message)
  end
end
