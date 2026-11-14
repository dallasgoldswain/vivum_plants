# Every stock change for one item (SE02, D157–D160): one transaction that locks the item,
# then its balances, writes the movement and the balance together, and checks the rules:
# no negative stock (the database refuses it too), saleable stock never below what's held,
# a specimen never more than one, and a specimen held at most once.
class Stock::Ledger
  class Refused < StandardError; end

  attr_reader :item, :member

  def initialize(item, member:)
    @item = item
    @member = member
  end

  def receive!(quantity:, location:, reason: nil, occurred_at: Time.current)
    write(:receipt, quantity, location, reason: reason, occurred_at: occurred_at) { change(location, saleable: quantity) }
  end

  def move!(quantity:, from:, to:, bucket: "saleable", reason: nil)
    raise Refused, "Choose a different location to move to." if from == to

    write(:move, quantity, from, to_location: to, bucket: bucket, reason: reason) do
      change(from, bucket.to_sym => -quantity)
      change(to, bucket.to_sym => quantity)
    end
  end

  def mark_unavailable!(quantity:, location:, reason:)
    write(:mark_unavailable, quantity, location, reason: reason) { change(location, saleable: -quantity, unavailable: quantity) }
  end

  def mark_available!(quantity:, location:, reason: nil)
    write(:mark_available, quantity, location, reason: reason) { change(location, saleable: quantity, unavailable: -quantity) }
  end

  def lose!(quantity:, location:, bucket: "saleable", reason:)
    write(:loss, quantity, location, bucket: bucket, reason: reason) { change(location, bucket.to_sym => -quantity) }
  end

  # A count of saleable units at a location becomes an adjustment for the difference (D160).
  def count!(counted:, location:, reason:)
    raise Refused, "Enter a count of 0 or more." if counted.to_i.negative?

    transaction do
      current = item.balances.find_by(stock_location: location)&.saleable.to_i
      delta = counted.to_i - current
      raise Refused, "That matches what's recorded; nothing to adjust." if delta.zero?

      change(location, saleable: delta)
      record(:adjustment, delta, location, reason: reason)
    end
  end

  def hold!(quantity:, location:, held_for:, expires_at:)
    raise Refused, "Choose when the hold ends." if expires_at.blank?
    raise Refused, "The hold must end in the future." if expires_at <= Time.current

    transaction do
      raise Refused, "This specimen is already held." if item.specimen? && item.holds.current.exists?

      available = position(location).available
      raise Refused, "Only #{available} available at #{location.name}." if quantity > available

      hold = item.holds.create!(stock_location: location, quantity: quantity, held_for: held_for, expires_at: expires_at, created_by: member)
      record(:hold, quantity, location, stock_hold: hold, reason: hold.held_for)
      hold
    end
  end

  def release!(hold) = finish!(hold, "released", :release)
  def expire!(hold) = finish!(hold, "expired", :expire, require_current: false)

  # The held units leave: on hand drops and the hold ends (D159). A specimen that came from a
  # collection records the sale on the plant's timeline (SE04, D162).
  def fulfil!(hold)
    transaction do
      hold.lock!
      raise Refused, "That hold has ended." unless hold.current?

      hold.update!(state: "fulfilled", resolved_at: Time.current)
      change(hold.stock_location, saleable: -hold.quantity)
      record(:fulfil, hold.quantity, hold.stock_location, stock_hold: hold, reason: hold.held_for)
      item.plant&.change_status!("sold", reason: "Sold by #{item.seller.name} (#{item.code})") if item.specimen?
      hold
    end
  end

  # Takes a specimen back to the collection of the member who moved it in (D162).
  def to_collection!
    raise Refused, "Only a specimen moved from a collection can go back." unless item.specimen? && item.plant
    raise Refused, "Only #{item.moved_by&.email_address || 'the member who moved it'} can take it back." unless member == item.moved_by

    transaction do
      raise Refused, "Release its hold first." if item.holds.current.exists?

      item.balances.includes(:stock_location).each do |balance|
        %i[ saleable unavailable ].each do |bucket|
          quantity = balance.public_send(bucket)
          next if quantity.zero?

          change(balance.stock_location, bucket => -quantity)
          record(:to_collection, quantity, balance.stock_location, bucket: bucket.to_s, reason: "Back to #{member.email_address}'s collection")
        end
      end
      item.update!(archived_at: Time.current)
      item.plant.change_status!("active", reason: "Back from #{item.seller.name} stock (#{item.code})")
    end
  end

  def position(location)
    balance = item.balances.find_by(stock_location: location)
    Stock::Position.new(location, balance&.saleable.to_i, balance&.unavailable.to_i, item.holds.current.where(stock_location: location).sum(:quantity))
  end

  private
    def write(kind, quantity, location, **attributes)
      quantity = quantity.to_i
      raise Refused, "Enter a quantity of 1 or more." unless quantity.positive?
      raise Refused, "Choose a location." unless location

      transaction do
        yield
        record(kind, quantity, location, **attributes)
      end
    end

    def transaction(&)
      StockItem.transaction do
        item.lock!
        yield
      end
    rescue ActiveRecord::StatementInvalid => error
      raise unless error.cause.is_a?(PG::CheckViolation)

      raise Refused, "There isn't that much stock there."
    end

    def change(location, saleable: 0, unavailable: 0)
      raise Refused, "That location belongs to another business." unless location.seller_id == item.seller_id

      balance = item.balances.lock.find_or_initialize_by(stock_location: location)
      balance.saleable += saleable
      balance.unavailable += unavailable
      raise Refused, "There isn't that much stock at #{location.name}." if balance.saleable.negative? || balance.unavailable.negative?

      held = item.holds.current.where(stock_location: location).sum(:quantity)
      raise Refused, "#{held} #{held == 1 ? 'is' : 'are'} held at #{location.name}; release the hold first." if saleable.negative? && balance.saleable < held

      balance.save!
      raise Refused, "A specimen is one plant; use a batch for more." if item.specimen? && item.balances.sum("saleable + unavailable") > 1
    end

    def record(kind, quantity, location, **attributes)
      item.movements.create!(seller: item.seller, kind: kind.to_s, quantity: quantity, stock_location: location, member: member, occurred_at: Time.current, **attributes)
    end

    def finish!(hold, state, kind, require_current: true)
      transaction do
        hold.lock!
        return hold unless hold.active?
        raise Refused, "That hold has ended." if require_current && !hold.current?

        hold.update!(state: state, resolved_at: Time.current)
        record(kind, hold.quantity, hold.stock_location, stock_hold: hold, reason: hold.held_for)
        hold
      end
    end
end
