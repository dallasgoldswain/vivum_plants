# Runs inside the Flipper console (a Rack app, not a controller) so flag changes can be
# audited with the operator who made them. The route is already limited to operators by
# OperatorConstraint.
#
# A release refused by FlagReleaseGuard (D76) goes back to the feature page, where the
# console shows the reason.
class FlagConsoleContext
  FEATURE_PATH = %r{\A/features/(?<key>[^/]+)}

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    Current.request = request
    Current.session = Session.find_by(id: request.cookie_jar.signed[:session_id])
    @app.call(env)
  rescue FlagReleaseGuard::Refused => refusal
    key = request.path_info[FEATURE_PATH, :key]
    location = "#{request.script_name}/features/#{key}?#{{ error: refusal.message }.to_query}"
    [ 303, { "location" => location, "content-type" => "text/plain" }, [ refusal.message ] ]
  end
end
