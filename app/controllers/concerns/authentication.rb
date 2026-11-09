module Authentication
  extend ActiveSupport::Concern

  TWO_FACTOR_CHALLENGE_TTL = 5.minutes

  included do
    before_action :require_authentication
    before_action :require_verified_email
    before_action :require_two_factor_enrolment
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_verified_email, **options
      skip_before_action :require_two_factor_enrolment, **options
    end

    def allow_unverified_email_access(**options)
      skip_before_action :require_verified_email, **options
      skip_before_action :require_two_factor_enrolment, **options
    end

    def allow_without_two_factor_enrolment(**options)
      skip_before_action :require_two_factor_enrolment, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def current_user
      Current.user
    end

    def require_authentication
      resume_session || request_authentication
    end

    def require_verified_email
      redirect_to new_email_verification_path unless Current.user&.email_verified?
    end

    # Operators and seller owners cannot use the app until they set up a second step.
    def require_two_factor_enrolment
      user = Current.user
      if user && user.two_factor_required? && !user.two_factor_enabled?
        redirect_to new_two_factor_enrolment_path, alert: "Set up two-step sign-in to continue."
      end
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    # Signs in directly, or hands over to the second step when the user has one.
    def sign_in(user)
      if user.two_factor_enabled?
        session[:two_factor_user] = user.signed_id(purpose: :two_factor, expires_in: TWO_FACTOR_CHALLENGE_TTL)
        redirect_to new_two_factor_challenge_path
      else
        start_new_session_for user
        redirect_to after_authentication_url
      end
    end

    def pending_two_factor_user
      User.find_signed(session[:two_factor_user], purpose: :two_factor) if session[:two_factor_user]
    end

    def clear_pending_two_factor
      session.delete(:two_factor_user)
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
