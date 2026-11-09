class HomeController < ApplicationController
  skip_verify_authorized

  def show
    @memberships = Current.user.memberships.includes(:seller)
  end
end
