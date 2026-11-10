# Sell → Members: everyone can see the team; owners invite, change roles and remove (SO02, D61).
class Sell::MembershipsController < Sell::BaseController
  requires_capability "seller.members"
  before_action :set_membership, only: %i[ update destroy ]

  def index
    authorize! Membership, to: :index?
    @memberships = authorized_scope(Membership.all).includes(:user).order(:created_at)
    @invitations = allowed_to?(:create?, Membership) ? authorized_scope(Invitation.pending).order(:created_at) : Invitation.none
    @invitation = Invitation.new(role: "manager")
  end

  def update
    if @membership.update(role: params.expect(membership: [ :role ])[:role])
      Audit.record("membership.role_changed", target: @membership, details: { role: @membership.role, seller_id: @membership.seller_id })
      redirect_to sell_members_path, notice: "Role updated."
    else
      redirect_to sell_members_path, alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @membership.destroy
      Audit.record("membership.removed", target: @membership, details: { role: @membership.role, seller_id: @membership.seller_id, user_id: @membership.user_id })
      redirect_to(@membership.user == Current.user ? root_path : sell_members_path, notice: "Member removed.", status: :see_other)
    else
      redirect_to sell_members_path, alert: @membership.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_membership
      @membership = authorized_scope(Membership.all).find(params[:id])
      authorize! @membership
    end
end
