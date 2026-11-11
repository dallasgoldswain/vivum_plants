# Public terms of use, privacy notice and seller terms (draft v0 for the pilot, D55, D60).
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

  def seller_terms
    @purpose = ConsentRecord.purpose(:seller_terms)
  end

  # Public steps for deleting an account, for app stores (OF01, D73).
  def account_deletion
  end
end
