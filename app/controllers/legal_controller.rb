# Public terms of use and privacy notice (draft v0 for the pilot, D55).
class LegalController < ApplicationController
  layout "legal"
  allow_unauthenticated_access
  skip_verify_authorized

  def terms
    @purpose = ConsentRecord.purpose(:terms)
  end

  def privacy
    @purpose = ConsentRecord.purpose(:privacy)
  end
end
