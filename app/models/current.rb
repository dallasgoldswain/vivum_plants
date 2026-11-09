class Current < ActiveSupport::CurrentAttributes
  attribute :session, :membership
  delegate :user, to: :session, allow_nil: true

  def session=(session)
    super
    self.membership = session&.membership
  end

  def seller
    membership&.seller
  end
end
