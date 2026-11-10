class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @url = invitation_url(invitation.acceptance_token)
    subject = invitation.seller? ? "Your invite to sell on VIVUM Plants" : "Join #{invitation.business_label} on VIVUM Plants"
    mail subject: subject, to: invitation.email_address
  end
end
