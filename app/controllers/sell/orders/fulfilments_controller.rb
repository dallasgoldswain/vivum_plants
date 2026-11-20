# Marks a reserved order collected or shipped (D181, D182): its stock leaves. Unpaid orders
# need the member to confirm.
class Sell::Orders::FulfilmentsController < Sell::BaseController
  include OrderScoped

  def create
    change_order(@order.pickup? ? "Collected." : "Shipped.") do
      @order.fulfil!(member: Current.user, unpaid_confirmed: params[:unpaid_confirmed] == "1", courier: params[:courier], tracking_reference: params[:tracking_reference])
    end
  end
end
