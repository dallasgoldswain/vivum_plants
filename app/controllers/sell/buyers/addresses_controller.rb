# A buyer's delivery addresses (D175).
class Sell::Buyers::AddressesController < Sell::BaseController
  include BuyerScoped

  def create
    address = @buyer.addresses.new(params.expect(address: %i[ label recipient street suburb city province postal_code default ]))
    if address.save
      back_to_buyer(notice: "Address added.")
    else
      back_to_buyer(alert: address.errors.full_messages.to_sentence)
    end
  end

  def default
    @buyer.addresses.find(params[:id]).update!(default: true)
    back_to_buyer(notice: "Default address changed.")
  end

  def destroy
    address = @buyer.addresses.find(params[:id])
    address.destroy!
    @buyer.addresses.first&.update!(default: true) if address.default?
    back_to_buyer(notice: "Address removed.")
  end
end
