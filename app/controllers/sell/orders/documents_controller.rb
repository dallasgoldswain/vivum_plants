# A receipt, tax invoice or credit note as a page or a PDF (RC01, D191).
class Sell::Orders::DocumentsController < Sell::BaseController
  include OrderScoped
  requires_capability "seller.receipts"

  def show
    @document = @order.documents.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        send_data OrderDocument::Pdf.new(@document).render, filename: "#{@document.reference}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end
end
