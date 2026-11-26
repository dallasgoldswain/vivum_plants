require "csv"

# Sell → Buyers (BY01, D171, D176): owners and managers manage buyers; host/packers see
# names and aliases only. Deleting is the buyer's data request (D177), for owners.
class Sell::BuyersController < Sell::BaseController
  requires_capability "seller.buyers"
  requires_capability "privacy.buyer_dsr", only: :destroy
  before_action :set_buyer, only: %i[ show edit update destroy ]

  def index
    authorize! Buyer
    @contacts = allowed_to?(:see_contacts?, Buyer)
    buyers = authorized_scope(Buyer.active).includes(:aliases).by_name
    respond_to do |format|
      format.html do
        @buyers = buyers.search(params[:q]).limit(200)
        @aliases = authorized_scope(BuyerAlias.all).unlinked.by_name.limit(200)
      end
      format.csv do
        authorize! Buyer, to: :create?
        send_data buyers_csv(buyers.includes(:addresses, :consents)), filename: "buyers-#{Date.current.iso8601}.csv", type: "text/csv"
      end
    end
  end

  def show
    @orders = @buyer.orders.includes(:lines).newest_first.limit(20)
    @holds = @buyer.holds.includes(:stock_item, :stock_location).order(created_at: :desc).limit(20)
    @consents = @buyer.consents.order(created_at: :desc, id: :desc)
    @unlinked_aliases = Current.seller.buyer_aliases.unlinked.by_name
    @others = Current.seller.buyers.active.where.not(id: @buyer.id).by_name
  end

  def new
    authorize! Buyer, to: :create?
    @buyer = Current.seller.buyers.new(name: params[:name])
  end

  def create
    authorize! Buyer, to: :create?
    @buyer = Current.seller.buyers.new(buyer_params)
    return create_for_alias if params[:alias_id].present?

    if @buyer.save
      redirect_to sell_buyer_path(@buyer), notice: "#{@buyer.name} added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @buyer.update(buyer_params)
      redirect_to sell_buyer_path(@buyer), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @buyer.erase!
    redirect_to sell_buyers_path, notice: "The buyer's details are deleted."
  rescue ActiveRecord::RecordNotDestroyed => error
    redirect_to sell_buyer_path(@buyer), alert: error.message
  end

  private
    # From Closeout's unresolved aliases (D221): the new buyer takes the alias, by hand.
    def create_for_alias
      buyer_alias = authorized_scope(BuyerAlias.all).unlinked.find(params[:alias_id])
      authorize! buyer_alias, to: :update?
      Buyer.transaction do
        @buyer.save!
        buyer_alias.update!(buyer: @buyer)
      end
      Audit.record("buyer_alias.linked", target: buyer_alias, details: { buyer_id: @buyer.id, created: true })
      redirect_back_or_to sell_buyer_path(@buyer), notice: "#{@buyer.name} added and linked to #{buyer_alias.label}."
    rescue ActiveRecord::RecordInvalid => error
      redirect_back_or_to sell_buyers_path, alert: error.record.errors.full_messages.to_sentence
    end

    def set_buyer
      @buyer = authorized_scope(Buyer.active).find(params[:id])
      authorize! @buyer
    end

    def buyer_params = params.expect(buyer: %i[ name phone email contact_preference ])

    def buyers_csv(buyers)
      CSV.generate do |csv|
        csv << %w[ name phone email contact_preference verified_at aliases default_address whatsapp_messages marketing created_at ]
        buyers.each do |buyer|
          csv << [ buyer.name, buyer.phone, buyer.email, buyer.contact_preference, buyer.verified_at&.iso8601, buyer.aliases.map(&:label).join("; "), buyer.default_address&.one_line, buyer.consent?(:whatsapp_messages), buyer.consent?(:marketing), buyer.created_at.iso8601 ]
        end
      end
    end
end
