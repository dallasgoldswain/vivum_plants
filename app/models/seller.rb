class Seller < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :invitations, dependent: :delete_all
  has_many :users, through: :memberships
  belongs_to :plan

  # Pilot and comp are free and never charged; paid needs a Paystack subscription, which
  # isn't built yet, so it can't be chosen (SB03, D64).
  enum :billing_mode, { pilot: "pilot", comp: "comp", paid: "paid" }, validate: true, prefix: :billing

  BILLING_FIELDS = %w[ billing_mode plan_id free_until ].freeze

  # Why an operator changed billing; required for billing changes and kept in the audit log.
  attribute :audit_reason, :string

  validates :name, presence: true
  validate :paid_needs_paystack
  validates :audit_reason, presence: { message: "is required when changing billing" }, on: :update, if: :billing_changed?

  before_validation -> { self.plan ||= Plan.default }, on: :create

  scope :free_period_ended, -> { where(billing_mode: %w[ pilot comp ]).where(free_until: ...Date.current) }

  def free? = billing_pilot? || billing_comp?

  # D67: owners are prompted to choose a paid plan; access is not reduced.
  def free_period_ended?
    free? && free_until.present? && free_until.past?
  end

  def entitled_to?(entitlement) = plan.entitled_to?(entitlement)

  # Members plus pending staff invites count against the plan's member limit (D66).
  def seats_used
    memberships.count + invitations.staff.pending.count
  end

  def seats_available? = seats_used < plan.member_limit

  private
    def billing_changed?
      (changed & BILLING_FIELDS).any?
    end

    def paid_needs_paystack
      errors.add(:billing_mode, "Paid needs Paystack subscriptions, which aren't available yet") if billing_paid? && billing_mode_changed?
    end
end
