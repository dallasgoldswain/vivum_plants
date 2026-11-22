# Payments and refunds recorded by hand (PY03 manual, D189, D194, D195). Never edited;
# voided with a reason.
class Sell::Orders::PaymentsController < Sell::BaseController
  include OrderScoped
  requires_capability "payments.manual"

  def create
    attributes = { amount_cents: Order.cents(params[:amount]), method: params[:method], paid_on: paid_on, reference: params[:reference], member: Current.user }
    if params[:kind] == "refund"
      change_order("Refund recorded.") { @order.record_refund!(**attributes, reason: params[:reason]) }
    else
      change_order("Payment recorded.") { @order.record_payment!(**attributes) }
    end
  end

  def void
    payment = @order.payments.find(params[:id])
    change_order("Voided.") { @order.void_payment!(payment, reason: params[:reason], member: Current.user) }
  end

  private
    def paid_on
      Date.iso8601(params[:paid_on].to_s)
    rescue Date::Error
      nil
    end
end
