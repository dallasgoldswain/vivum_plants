# Flipper adapter wrapper used in production (HM02, D76): turning a capability on for
# everyone, or for a percentage, is refused until its help topic is reviewed. Enabling it
# for one user or seller (founder testing, pilot sellers) and turning anything off still work.
class FlagReleaseGuard < Flipper::Adapters::Wrapper
  BROAD_GATES = %i[ boolean percentage_of_actors percentage_of_time ].freeze

  class Refused < StandardError; end

  def enable(feature, gate, thing)
    if BROAD_GATES.include?(gate.key) && thing.value.present? && thing.value != 0
      blocker = HelpTopic.release_blocker(feature.key)
      raise Refused, blocker if blocker
    end

    super
  end
end
