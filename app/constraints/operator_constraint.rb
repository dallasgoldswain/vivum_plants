# Route constraint for mounted Rack apps (e.g. the flag console) that can't use
# Madmin::ApplicationController's checks: a verified platform operator with two-step
# sign-in. Anyone else gets no route (404).
class OperatorConstraint
  def self.matches?(request)
    session_id = request.cookie_jar.signed[:session_id]
    user = session_id && Session.find_by(id: session_id)&.user
    !!(user&.platform_operator? && user.email_verified? && user.two_factor_enabled?)
  end
end
