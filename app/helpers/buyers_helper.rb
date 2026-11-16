# Buyers and aliases (D171–D178).
module BuyersHelper
  # The For list on a hold: buyers, then aliases not yet linked.
  def holder_options
    buyers = Current.seller.buyers.active.by_name.map { [ it.name, "buyer:#{it.id}" ] }
    aliases = Current.seller.buyer_aliases.unlinked.by_name.map { [ it.label, "alias:#{it.id}" ] }
    [ [ "Buyers", buyers ], [ "Aliases", aliases ] ].reject { it.last.empty? }
  end

  def phone_label(phone) = PhoneNumber.format(phone)

  def verification_badge(buyer)
    if buyer.verified?
      tag.span("Verified", class: "badge-secondary", title: "Confirmed #{l(buyer.verified_at.to_date, format: :long)}")
    else
      tag.span("Unverified", class: "badge-outline")
    end
  end

  def consent_summary(buyer, purpose) = buyer.consent?(purpose) ? "Agreed" : "Not agreed"
end
