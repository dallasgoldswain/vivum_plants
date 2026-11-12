# The collector's timezone, which decides what "today" is for reminders (D117).
class Settings::TimeZonesController < ApplicationController
  skip_verify_authorized # acts only on Current.user

  def update
    if Current.user.update(time_zone: params[:time_zone])
      redirect_to settings_account_path, notice: "Timezone saved."
    else
      redirect_to settings_account_path, alert: "Choose a timezone from the list."
    end
  end
end
