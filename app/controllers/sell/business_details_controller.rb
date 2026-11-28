# The business profile (BR01, D193, D250–D258): the legal name, VAT number, address and
# contact details that receipts copy when they're issued, plus the logo and links that
# sale cards, receipts and slips show. Owners only; every change is audited.
class Sell::BusinessDetailsController < Sell::BaseController
  DETAILS = %w[ legal_name vat_number address phone contact_email ].freeze
  LINKS = %w[ instagram_url facebook_url youtube_url whatsapp_number show_instagram show_facebook show_youtube show_whatsapp card_link ].freeze

  before_action { authorize! Current.seller, to: :update? }

  def edit
  end

  def update
    seller = Current.seller
    seller.assign_attributes(params.expect(seller: [ *permitted_fields, :logo, :remove_logo ]).except(:logo, :remove_logo))
    changed = seller.changed
    return render(:edit, status: :unprocessable_entity) unless seller.valid?

    change_logo(seller)
    seller.save!
    Audit.record("seller.business_details_changed", target: seller) if changed.intersect?(DETAILS)
    Audit.record("seller.links_changed", target: seller, details: { shown: seller.shown_links.map(&:key), card_link: seller.card_link }) if changed.intersect?(LINKS)
    redirect_to edit_sell_business_details_path, notice: "Saved. New receipts and sale cards use these details."
  rescue Seller::Identity::LogoRejected => error
    seller.errors.add(:base, error.message)
    render :edit, status: :unprocessable_entity
  end

  private
    def permitted_fields
      fields = DETAILS.map(&:to_sym)
      fields += LINKS.map(&:to_sym) if capability?("seller.social_links")
      fields
    end

    def change_logo(seller)
      return unless capability?("seller.logo")

      if (upload = params.dig(:seller, :logo)).present?
        seller.replace_logo!(upload)
        Audit.record("seller.logo_changed", target: seller)
      elsif params.dig(:seller, :remove_logo) == "1" && seller.logo.attached?
        seller.logo.detach
        Audit.record("seller.logo_removed", target: seller)
      end
    end
end
