module Madmin
  # Operators issue seller invites only; staff invites come from owners in Sell → Members.
  class InvitationsController < Madmin::ResourceController
    def create
      super
      @record.deliver_later if @record.persisted?
    end

    def resend
      @record.resend!
      redirect_to resource.show_path(@record), notice: "Invite sent again. Earlier links no longer work."
    rescue Invitation::NotAcceptable => error
      redirect_to resource.show_path(@record), alert: error.message
    end

    def revoke
      @record.revoke!
      redirect_to resource.show_path(@record), notice: "Invite revoked."
    end

    private
      def resource_params
        super.merge(kind: "seller", role: "owner", invited_by: Current.user)
      end
  end
end
