# Runs inside the Flipper console (a Rack app, not a controller) so flag changes can be
# audited with the operator who made them. The route is already limited to operators by
# OperatorConstraint.
class FlagConsoleContext
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    Current.request = request
    Current.session = Session.find_by(id: request.cookie_jar.signed[:session_id])
    @app.call(env)
  end
end
