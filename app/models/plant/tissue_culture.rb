# Purchased tissue culture plantlets (TC02–TC05, PL06, D128–D133): a stage with dated
# history, losses as a status, and splitting a record that holds several plants.
module Plant::TissueCulture
  extend ActiveSupport::Concern

  class SplitRefused < StandardError; end

  included do
    belongs_to :split_from, class_name: "Plant", optional: true
    has_many :split_records, class_name: "Plant", foreign_key: :split_from_id, dependent: :nullify, inverse_of: :split_from

    validates :tc_stage, inclusion: { in: Plant::TC_STAGES }, allow_nil: true
  end

  def tc_established? = tc_stage == "established"

  # Sets the stage from a date and writes a stage entry on the timeline (D128). A stage change
  # never comes from a check (TC04).
  def change_stage!(stage, on: Date.current, idempotency_key: SecureRandom.uuid)
    raise ArgumentError, "unknown stage" unless Plant::TC_STAGES.include?(stage)
    raise Plant::Placement::MoveRefused, "Choose a date that isn't in the future." if on > Date.current

    user.care_events.find_by(idempotency_key: idempotency_key) || transaction do
      update!(tc_stage: stage, tc_origin: true)
      care_events.create!(user: user, kind: "stage", stage: stage, occurred_at: placement_time(on), idempotency_key: idempotency_key)
    end
  end

  # The date the current stage began.
  def tc_stage_since = care_events.where(kind: "stage").maximum(:occurred_at)&.to_date

  # Open reminders suggested for a TC stage, to review once established (D132).
  def open_tc_reminders = care_schedules.running.tc_stage

  # Moves part of this record's quantity into new records with their own numbers (PL06,
  # D133). The total never grows: 5 split as [3] keeps 2 here and makes one record of 3.
  # Each new record copies identity, stage, environment, setup, purchase and guidance switches
  # (D138), and the ticked reminders.
  def split!(quantities, copy_schedules: [], on: Date.current)
    quantities = quantities.map(&:to_i).select(&:positive?)
    raise SplitRefused, "Enter how many go into each new record." if quantities.empty?
    raise SplitRefused, "Keep at least 1 in #{record_id}: it has #{quantity}." if quantities.sum >= quantity

    transaction do
      environment = current_environment
      setup = current_setup
      created = quantities.map do |count|
        user.plants.create!(slice(:display_name, :botanical_name, :cultivar, :common_name, :nickname, :growing_context, :tc_origin, :tc_stage, :origin_note, :tags, :acquisition_id, :guidance_library, :guidance_ai, :guidance_revision_id)
          .merge(quantity: count, split_from: self, status: active? ? status : "active")).tap do |part|
          part.move_to!(environment, on: on) if environment
          part.change_setup!(setup.slice(:container, :size, :size_unit, :watering_method, :recipe_version_id).symbolize_keys, on: on) if setup
          copy_schedules.each { copy_schedule_to(it, part) }
          part.care_events.create!(user: user, kind: "splitting", note: "Split from #{record_id} (#{count} of #{quantity})", occurred_at: placement_time(on), idempotency_key: SecureRandom.uuid)
        end
      end
      care_events.create!(user: user, kind: "splitting", note: "Split #{quantities.sum} into #{created.map(&:record_id).to_sentence}; #{quantity - quantities.sum} kept here", occurred_at: placement_time(on), idempotency_key: SecureRandom.uuid)
      update!(quantity: quantity - quantities.sum)
      created
    end
  end

  private
    def copy_schedule_to(schedule, plant)
      plant.care_schedules.create!(user: user, **schedule.slice(:kind, :label, :note, :interval, :interval_unit, :mode, :origin).symbolize_keys, starts_on: schedule.open_task&.due_on || Date.current).start!
    end
end
