# Settings → Account: export your data and delete your account (§26, PR05, PR07; D68–D73).
class Settings::AccountController < ApplicationController
  skip_verify_authorized # acts only on Current.user

  def show
    exports = Current.user.data_requests.export.newest_first
    @export_in_progress = exports.open.first
    @latest_export = exports.completed.first
    @sole_owned_sellers = Current.user.sole_owned_sellers.to_a
  end
end
