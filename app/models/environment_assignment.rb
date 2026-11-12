# A plant's stay in an environment, from the day it moved in until it moved out (EN03, D93).
# The open stay (no end date) is the plant's current environment; ended stays are history.
class EnvironmentAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :plant
  belongs_to :environment

  validates :started_on, presence: true
  validate :dates_in_order
  validate :same_owner

  scope :current, -> { where(ended_on: nil) }
  scope :chronological, -> { order(:started_on, :id) }

  def current? = ended_on.nil?

  # Whether the plant's growing context differs from what this environment suggests and
  # the collector hasn't answered the offer yet (D91).
  def context_offer?
    current? && !context_answered? && (suggested = environment.suggested_context).present? && suggested != plant.growing_context
  end

  def covers?(date)
    started_on <= date && (ended_on.nil? || date < ended_on)
  end

  private
    def dates_in_order
      errors.add(:ended_on, "can't be before the move-in date") if ended_on && started_on && ended_on < started_on
    end

    def same_owner
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
      errors.add(:environment, "must be yours") if environment && environment.user_id != user_id
    end
end
