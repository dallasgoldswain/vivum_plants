# Live sale sessions, lots and claims (D209–D218).
module SalesHelper
  def session_status_badge(session)
    tag.span(session.status.capitalize, class: session.live? ? "badge" : (session.closed? ? "badge-outline" : "badge-secondary"))
  end

  def lot_state_label(lot)
    if lot.payment_missed? && lot.holding? then "Payment missed"
    elsif lot.won? && lot.transferred? then "Backup won"
    else { "queued" => "Up next", "open" => "Open", "won" => "Won", "passed" => "Passed", "returned" => "Returned to stock", "relisted" => "Relisted" }.fetch(lot.state)
    end
  end

  def claim_state_label(claim)
    return "Payment missed" if claim.payment_missed? && claim.stock_hold&.current?

    { "held" => "Held", "waitlisted" => "Waitlist ##{claim.position}", "returned" => "Returned to stock", "removed" => "Removed", "ended" => "Waitlist ended" }.fetch(claim.state)
  end

  def host_options(seller) = seller.memberships.includes(:user).map { [ it.user.email_address, it.user_id ] }
end
