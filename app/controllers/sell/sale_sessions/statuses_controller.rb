# Goes live, pauses or closes a session (LS01, D210, D216).
class Sell::SaleSessions::StatusesController < Sell::BaseController
  include SaleSessionScoped
  before_action { authorize! @sale_session, to: :update? }

  def update
    case params[:status]
    when "live" then @sale_session.go_live!(Current.user)
    when "paused" then @sale_session.pause!(Current.user)
    when "closed" then @sale_session.close!(Current.user)
    else return back(alert: "Choose what to do.")
    end
    back(notice: "#{@sale_session.name} is #{@sale_session.status}.")
  end
end
