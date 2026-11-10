# Owners invite staff by email and role, resend and cancel (D59, D61).
class Sell::InvitationsController < Sell::BaseController
  requires_capability "seller.members"
  before_action :set_invitation, only: %i[ resend destroy ]

  def create
    @invitation = Current.seller.invitations.new(params.expect(invitation: %i[ email_address role ]).merge(kind: "staff", invited_by: Current.user))
    authorize! @invitation

    if @invitation.save
      @invitation.deliver_later
      redirect_to sell_members_path, notice: "Invite sent."
    else
      redirect_to sell_members_path, alert: @invitation.errors.full_messages.to_sentence
    end
  end

  def resend
    @invitation.resend!
    redirect_to sell_members_path, notice: "Invite sent again. Earlier links no longer work."
  end

  def destroy
    @invitation.revoke!
    redirect_to sell_members_path, notice: "Invite cancelled.", status: :see_other
  end

  private
    def set_invitation
      @invitation = authorized_scope(Invitation.all).find(params[:id])
      authorize! @invitation, to: action_name == "destroy" ? :revoke? : :resend?
    end
end
