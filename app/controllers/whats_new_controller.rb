# User-facing release notes from WHATS_NEW.md (D79). Opening the page clears the dot on
# the sidebar link.
class WhatsNewController < ApplicationController
  allow_unauthenticated_access
  skip_verify_authorized
  before_action :resume_session

  def show
    Current.user&.update_column(:whats_new_seen_at, Time.current)
  end
end
