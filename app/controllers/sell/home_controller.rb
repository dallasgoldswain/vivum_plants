class Sell::HomeController < Sell::BaseController
  def show
    authorize! Current.seller, to: :show?
  end
end
