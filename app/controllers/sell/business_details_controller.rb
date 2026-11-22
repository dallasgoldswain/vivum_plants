# The business's legal name, VAT number, address and contact details (D193). Receipts copy
# them when they're issued. Owners only.
class Sell::BusinessDetailsController < Sell::BaseController
  before_action { authorize! Current.seller, to: :update? }

  def edit
  end

  def update
    if Current.seller.update(params.expect(seller: %i[ legal_name vat_number address phone contact_email ]))
      Audit.record("seller.business_details_changed", target: Current.seller)
      redirect_to edit_sell_business_details_path, notice: "Saved. New receipts use these details."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
