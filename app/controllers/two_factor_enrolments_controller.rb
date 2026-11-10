# Sets up, or turns off, two-step sign-in for the signed-in user's own account.
class TwoFactorEnrolmentsController < ApplicationController
  layout "auth"
  allow_without_two_factor_enrolment
  skip_verify_authorized # acts only on Current.user
  rate_limit to: 10, within: 3.minutes, only: %i[ create destroy ], with: -> { redirect_to new_two_factor_enrolment_path, alert: "Try again later." }

  def new
    return redirect_to(root_path, notice: "Two-step sign-in is already on.") if Current.user.two_factor_enabled?

    session[:pending_otp_secret] ||= User.generate_otp_secret
    @secret = session[:pending_otp_secret]
    svg = RQRCode::QRCode.new(User.otp_provisioning_uri(@secret, Current.user.email_address))
      .as_svg(module_size: 4, use_path: true, viewbox: true)
    @qr_data_uri = "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  def create
    secret = session[:pending_otp_secret]

    if secret && User.valid_otp_for_secret?(secret, params[:code])
      session.delete(:pending_otp_secret)
      @backup_codes = Current.user.enable_two_factor!(secret)
      render :create
    else
      redirect_to new_two_factor_enrolment_path, alert: "That code didn't match. Check your authenticator app and try again."
    end
  end

  def destroy
    if Current.user.two_factor_required?
      redirect_to root_path, alert: "Two-step sign-in is required for your account."
    elsif Current.user.verify_second_factor(params[:code])
      Current.user.disable_two_factor!
      redirect_to root_path, notice: "Two-step sign-in is off."
    else
      redirect_to root_path, alert: "That code didn't match."
    end
  end
end
