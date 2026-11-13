# Recording a TC purchase (TC01, D127): one purchase group and one record per plantlet, each
# with its own P-number, the starting stage and, optionally, an environment.
class TissueCulture::Purchase
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :botanical_name, :string
  attribute :cultivar, :string
  attribute :growing_context, :string, default: "indoor"
  attribute :quantity, :integer, default: 1
  attribute :stage, :string, default: "sealed"
  attribute :source, :string
  attribute :acquired_on, :date
  attribute :deflasked_on, :date
  attribute :container_condition, :string
  attribute :cost, :string
  attribute :currency, :string, default: "ZAR"
  attribute :order_reference, :string
  attribute :arrival_notes, :string
  attribute :environment_id, :integer

  attr_accessor :user
  attr_reader :acquisition

  validates :name, presence: true, length: { maximum: 100 }
  validates :growing_context, inclusion: { in: Plant::GROWING_CONTEXTS }
  validates :stage, inclusion: { in: Plant::TC_STAGES }
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: Acquisition::MAX_PLANTLETS }
  validate :dates_not_in_future

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @acquisition = user.acquisitions.create!(
        name: name, tissue_culture: true, quantity: quantity, source: source, acquired_on: acquired_on, deflasked_on: deflasked_on,
        container_condition: container_condition.presence, cost: cost, currency: currency, order_reference: order_reference, arrival_notes: arrival_notes
      )
      environment = user.environments.active.find(environment_id) if environment_id
      started_on = [ acquired_on, deflasked_on ].compact.max || Date.current
      quantity.times do |index|
        plant = user.plants.create!(
          display_name: "#{name} #{index + 1}", botanical_name: botanical_name, cultivar: cultivar, growing_context: growing_context,
          tc_origin: true, quantity: 1, acquisition: @acquisition
        )
        plant.change_stage!(stage, on: stage == "sealed" ? (acquired_on || Date.current) : started_on)
        plant.move_to!(environment, on: Date.current) if environment
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    errors.add(:base, error.record.errors.full_messages.to_sentence)
    false
  end

  private
    def dates_not_in_future
      errors.add(:acquired_on, "can't be in the future") if acquired_on && acquired_on > Date.current
      errors.add(:deflasked_on, "can't be in the future") if deflasked_on && deflasked_on > Date.current
    end
end
