# Shown to an account waiting to be deleted when it signs in during the 30 days (D69).
class DeletionCancellationsController < ApplicationController
  layout "auth"
  allow_pending_deletion
  skip_verify_authorized # acts only on Current.user

  before_action -> { redirect_to root_path unless Current.user.deletion_pending? }

  def new
  end

  def create
    Current.user.cancel_deletion!
    redirect_to root_path, notice: "Welcome back. Your account is no longer being deleted."
  end
end
