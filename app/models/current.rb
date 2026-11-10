class Current < ActiveSupport::CurrentAttributes
  attribute :session, :membership
  attribute :ip_address, :user_agent, :request_id
  delegate :user, to: :session, allow_nil: true

  def session=(session)
    super
    self.membership = session&.membership
  end

  def seller
    membership&.seller
  end

  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.user_agent&.truncate(500)
    self.request_id = request.request_id
  end
end
