# The one place code asks whether a product capability is available (PRD FF01).
#
#   Capabilities.enabled?("seller.stock", user: Current.user, seller: Current.seller)
#
# Evaluation order, denying at the first failure:
#   1. registered in config/features.yml and implemented
#   2. turned on in Flipper globally, for the seller or for the user
#      (disabling a flag in the console clears every target: the emergency stop)
#   3. every dependency is enabled for the same user and seller
#   4. the seller holds the capability's entitlement (billing, B07)
# Authorisation (Action Policy) and user preferences are checked by the caller after this.
module Capabilities
  class << self
    def enabled?(key, user: nil, seller: nil)
      definition = registry[key]
      return false unless definition&.implemented?

      actors = [ seller, user ].compact
      return false unless Flipper.enabled?(definition.key, *actors)
      return false unless definition.depends_on.all? { |dep| enabled?(dep, user: user, seller: seller) }

      entitled?(definition, seller)
    end

    def registry
      @registry ||= Capability::Registry.load
    end

    # Swap the registry (tests) or reset it (code reload).
    attr_writer :registry

    def reset!
      @registry = nil
    end

    # Adds every registered key to Flipper so the console lists them all. In development,
    # implemented core capabilities are switched on globally (FF02). Never deletes Flipper
    # features; returns any that are not in the registry so they can be reviewed.
    def sync!(enable_implemented_core: Rails.env.development?)
      registry.each do |definition|
        Flipper.add(definition.key) unless Flipper.exist?(definition.key)
        Flipper.enable(definition.key) if enable_implemented_core && definition.implemented? && definition.state == "core"
      end
      Flipper.features.map(&:key) - registry.keys
    end

    private
      # Paid entitlements come with billing (B07); until then nothing is entitled.
      def entitled?(definition, _seller)
        definition.entitlement.nil?
      end
  end
end
