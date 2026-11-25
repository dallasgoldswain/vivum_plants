# Loads the sale session from the URL, scoped to what the member may see (D217), and sends
# them back to the page they acted from.
module SaleSessionScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "sales.sessions"
    before_action :set_sale_session
    rescue_from SaleSession::Refused, Stock::Ledger::Refused, with: :refused
    rescue_from ActiveRecord::RecordInvalid do |error|
      back(alert: error.record.errors.full_messages.to_sentence)
    end
  end

  private
    def set_sale_session
      @sale_session = authorized_scope(SaleSession.all).find(params[:sale_session_id])
    end

    def holder(prefix)
      @sale_session.holder(params[:"#{prefix}_choice"], params[:"#{prefix}_name"], member: Current.user)
    end

    def back(**flash) = redirect_back_or_to(sell_sale_session_host_path(@sale_session), **flash)
    def refused(error) = back(alert: error.message)
end
