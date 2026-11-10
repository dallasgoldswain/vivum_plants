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

      IGNORED_CHANGES = %w[ created_at updated_at ].freeze

      def audit_operator_action
        case action_name
        when "index"
          Audit.record("madmin.index", target_key: resource.model.name, details: { query: request.query_parameters.except("page") })
        when "show", "edit"
          Audit.record("madmin.#{action_name}", target: @record)
        when "create", "update"
          return unless response.redirect? && @record&.persisted?

          Audit.record("madmin.#{action_name}", target: @record, details: { changes: @record.saved_changes.except(*IGNORED_CHANGES) })
        when "destroy"
          return unless @record&.destroyed?

          Audit.record("madmin.destroy", target: @record, details: { attributes: @record.attributes.except(*IGNORED_CHANGES) })
        end
      end
  end
end
