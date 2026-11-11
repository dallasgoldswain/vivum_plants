module Madmin
  # Only verified platform operators with two-step sign-in can use /madmin.
  # The Authentication concern enforces sign-in, email verification and
  # two-step enrolment (always required for operators).
  #
  # Every view and change an operator makes is audited (PR08, D49).
  class ApplicationController < Madmin::BaseController
    include Rails.application.routes.url_helpers
    include ::Authentication

    before_action :require_platform_operator
    after_action :audit_operator_action, if: -> { is_a?(Madmin::ResourceController) }

    private
      # 404 rather than 403 so the area's existence isn't revealed.
      def require_platform_operator
        raise ActionController::RoutingError, "Not Found" unless Current.user&.platform_operator?
      end

      IGNORED_FIELDS = %w[ created_at updated_at ].freeze

      # Fields whose before/after values are safe to keep (not personal data). Every other
      # change is recorded by field name only (D53).
      AUDITED_VALUES = {
        "User" => %w[ platform_operator email_verified_at ],
        "Membership" => %w[ role seller_id user_id ],
        "Seller" => Seller::BILLING_FIELDS,
        "Plan" => %w[ key name monthly_price_cents member_limit photo_limit ai_extractions_per_month paid_branding active ],
        "Invitation" => %w[ kind role seller_id expires_at accepted_at revoked_at ]
      }.freeze

      def audit_operator_action
        case action_name
        when "index"
          Audit.record("madmin.index", target_key: resource.model.name,
            details: { searched: params[:q].present?, filtered: params[:filters].present?, scope: params[:scope] }.compact)
        when "show", "edit"
          Audit.record("madmin.#{action_name}", target: @record)
        when "create", "update"
          return unless response.redirect? && @record&.persisted?

          Audit.record("madmin.#{action_name}", target: @record, details: change_details(@record), reason: @record.try(:audit_reason).presence)
        when "destroy"
          Audit.record("madmin.destroy", target: @record) if @record&.destroyed?
        end
      end

      def change_details(record)
        changes = record.saved_changes.except(*IGNORED_FIELDS)
        allowed = AUDITED_VALUES.fetch(record.class.base_class.name, [])
        { changed_fields: changes.keys, values: changes.slice(*allowed) }
      end
  end
end
