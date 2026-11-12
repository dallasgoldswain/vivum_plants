# Where a plant grows and how it's set up, with history (EN03, PL05, D89–D93). Moves and
# setup changes also write a dated care event, so they show on the timeline (D92).
module Plant::Placement
  extend ActiveSupport::Concern

  class MoveRefused < StandardError; end

  included do
    has_many :environment_assignments, -> { chronological }, dependent: :delete_all
    has_one :current_assignment, -> { current }, class_name: "EnvironmentAssignment"
    has_one :current_environment, through: :current_assignment, source: :environment
    has_many :setups, -> { chronological }, class_name: "PlantSetup", dependent: :delete_all
  end

  def current_setup = setups.last

  # Moves the plant into an environment, or out of its current one when nil. The move date
  # can't be in the future or before the current stay began, so stays never overlap.
  def move_to!(environment, on: Date.current)
    current = current_assignment
    raise MoveRefused, "Choose an environment." if environment.nil? && current.nil?
    raise MoveRefused, "#{display_name} is already in #{environment.name}." if environment && current&.environment_id == environment.id
    raise MoveRefused, "Choose a date that isn't in the future." if on > Date.current
    raise MoveRefused, "#{display_name} moved into #{current.environment.name} on #{I18n.l(current.started_on, format: :long)}; choose that date or later." if current && on < current.started_on
    raise MoveRefused, "#{environment.name} is archived." if environment&.archived?

    transaction do
      current&.update!(ended_on: on)
      environment_assignments.create!(user: user, environment: environment, started_on: on) if environment
      care_events.create!(user: user, kind: "movement", environment: environment, from_environment: current&.environment, occurred_at: placement_time(on), idempotency_key: SecureRandom.uuid)
    end
    association(:current_assignment).reset
  end

  def change_setup!(attributes, on: Date.current)
    raise MoveRefused, "Choose a date that isn't in the future." if on > Date.current

    transaction do
      setup = setups.create!(attributes.merge(user: user, started_on: on))
      care_events.create!(user: user, kind: "setup", plant_setup: setup, occurred_at: placement_time(on), idempotency_key: SecureRandom.uuid)
      setup
    end
  end

  # A repot logs one repotting event and, when a container, size or substrate is given, a
  # new dated setup that the event points at, so the timeline shows one entry (D106).
  def repot!(event, setup_attributes)
    on = event.occurred_at.to_date
    raise MoveRefused, "Choose a date that isn't in the future." if on > Date.current

    transaction do
      if setup_attributes.symbolize_keys.except(:size_unit).values.any?(&:present?)
        event.plant_setup = setups.create!(setup_attributes.merge(user: user, started_on: on))
      end
      event.save!
      event
    end
  end

  # The environment and setup in place on a date, for timeline entries (PL05).
  def setting_on(date)
    assignment = environment_assignments.select { it.covers?(date) }.last
    setup = setups.select { it.started_on <= date }.last
    [ assignment&.environment, setup ]
  end

  # Answers the context offer (D91): take the environment's suggested context, or keep ours.
  def answer_context_offer!(accept:)
    assignment = current_assignment or return
    transaction do
      update!(growing_context: assignment.environment.suggested_context) if accept && assignment.environment.suggested_context
      assignment.update!(context_answered: true)
    end
  end

  private
    # Today's moves happen now; a back-dated move sits at midday on its date.
    def placement_time(date)
      date == Date.current ? Time.current : date.in_time_zone.change(hour: 12)
    end
end
