# What changes an order's lines and stock (SE05, SE06, D180–D183). Each action locks the
# order, then the stock items in id order, and goes through Stock::Ledger in one transaction,
# so two orders for the last plant reserve once and a repeated cancel changes nothing.
module Order::Reserving
  extend ActiveSupport::Concern

  class Refused < StandardError; end

  def add_line!(item:, quantity:, member:, listing: nil, price_cents: nil)
    raise Refused, "That item belongs to another business." unless item.seller_id == seller_id
    raise Refused, "That listing is for another item." if listing && listing.stock_item_id != item.id

    changing(member, [ item ]) do
      raise Refused, "#{item.code} is already on this order; change its quantity instead." if lines.active.exists?(stock_item: item)

      price_cents ||= listing&.price_cents || item.price_cents
      raise Refused, "Enter a price for #{item.code}; it has none yet." if price_cents.nil?

      line = lines.create!(stock_item: item, listing: listing, quantity: quantity.to_i, description: listing&.title || item.label, agreed_price_cents: price_cents, unit_price_cents: price_cents)
      hold_line!(line, member) if reserved?
      line
    end
  end

  def change_quantity!(line, quantity:, member:)
    changing(member, [ line.stock_item ]) do
      line.lock!
      raise Refused, "That line is cancelled." unless line.active?
      next line if line.quantity == quantity.to_i

      let_go!(line, member) if line.stock_hold&.active?
      line.update!(quantity: quantity.to_i, stock_hold: nil)
      hold_line!(line, member) if reserved?
      line
    end
  end

  # Keeps the old price and the reason in the audit log (D183).
  def change_price!(line, price_cents:, reason:, member:)
    changing(member) do
      raise Refused, "Give a reason for the new price." if reason.to_s.strip.empty?
      raise Refused, "That line is cancelled." unless line.active?

      previous = line.unit_price_cents
      line.update!(unit_price_cents: price_cents, price_reason: reason)
      Audit.record("order.price_changed", actor: member, target: self, details: { line_id: line.id, from_cents: previous, to_cents: price_cents, reason: line.price_reason })
      line
    end
  end

  # A draft's line goes; a reserved order's line is cancelled with a reason (D183).
  def remove_line!(line, member:, reason: nil)
    changing(member, [ line.stock_item ]) do
      line.lock!
      next line unless line.active?

      if draft?
        line.destroy!
      else
        raise Refused, "Give a reason for cancelling the line." if reason.to_s.strip.empty?

        let_go!(line, member) if line.stock_hold&.active?
        line.update!(state: "cancelled", cancel_reason: reason)
        Audit.record("order.line_cancelled", actor: member, target: self, details: { line_id: line.id, reason: line.cancel_reason })
      end
      line
    end
  end

  # Holds every active line until one time (D180), all or nothing. On a reserved order it
  # moves the end of current holds and holds again any line whose hold ran out.
  def reserve!(expires_at:, member:)
    raise Refused, "Choose when the hold ends." if expires_at.blank?
    raise Refused, "The hold must end in the future." if expires_at <= Time.current

    changing(member, lines.active.includes(:stock_item).map(&:stock_item)) do
      raise Refused, "Add something to the order first." if lines.active.none?

      self.hold_expires_at = expires_at
      update!(state: "reserved")
      short = []
      lines.active.includes(:stock_hold, :stock_item).each do |line|
        if line.held?
          Stock::Ledger.new(line.stock_item, member: member).extend!(line.stock_hold, expires_at: expires_at)
        else
          hold_line!(line, member)
        end
      rescue Stock::Ledger::Refused => error
        short << "#{line.stock_item.code}: #{error.message}"
      end
      raise Refused, "Nothing was reserved. #{short.join(' ')}" if short.any?

      Audit.record("order.reserved", actor: member, target: self, details: { hold_expires_at: expires_at.iso8601 })
      self
    end
  end

  def cancel!(reason:, member:)
    changing(member, lines.includes(:stock_item).map(&:stock_item), require_open: false) do
      next self if cancelled?
      raise Refused, "A fulfilled order can't be cancelled." if fulfilled?
      raise Refused, "Give a reason for cancelling." if reason.to_s.strip.empty?

      lines.active.includes(:stock_hold, :stock_item).each { let_go!(it, member) if it.stock_hold&.active? }
      update!(state: "cancelled", cancel_reason: reason, cancelled_at: Time.current, cancelled_by: member)
      Audit.record("order.cancelled", actor: member, target: self, details: { reason: cancel_reason })
      self
    end
  end

  # Collected or shipped (D182): every active line's hold is fulfilled and the stock leaves.
  # An unpaid order is fulfilled only when the member confirms it (D181).
  def fulfil!(member:, unpaid_confirmed: false, courier: nil, tracking_reference: nil)
    changing(member, lines.active.includes(:stock_item).map(&:stock_item), require_open: false) do
      next self if fulfilled?
      raise Refused, "Reserve the order before fulfilling it." unless reserved?
      raise Refused, "This order hasn't been paid. Confirm you're fulfilling it unpaid." if unpaid? && !unpaid_confirmed

      active = lines.active.includes(:stock_hold, :stock_item).to_a
      raise Refused, "Add something to the order first." if active.empty?

      expired = active.reject(&:held?)
      raise Refused, "#{expired.map { it.stock_item.code }.to_sentence} #{expired.one? ? 'is' : 'are'} no longer held; reserve again first." if expired.any?

      active.each { Stock::Ledger.new(it.stock_item, member: member).fulfil!(it.stock_hold) }
      update!(state: "fulfilled", fulfilled_at: Time.current, fulfilled_by: member, courier: courier, tracking_reference: tracking_reference)
      Audit.record("order.fulfilled", actor: member, target: self, details: { unpaid: unpaid?, delivery_method: delivery_method })
      self
    end
  end

  private
    def changing(member, items = [], require_open: true)
      transaction do
        lock!
        raise Refused, "This order is #{state}; it can't change." if require_open && !open?

        StockItem.where(id: items.map(&:id).uniq).order(:id).lock.load
        yield
      end
    rescue ActiveRecord::RecordInvalid => error
      raise Refused, error.record.errors.full_messages.to_sentence
    rescue Stock::Ledger::Refused => error
      raise Refused, error.message
    end

    # The location with the most available stock that covers the line.
    def hold_line!(line, member)
      raise Refused, "The hold has ended; set a new end time first." unless hold_expires_at&.future?

      ledger = Stock::Ledger.new(line.stock_item, member: member)
      location = line.stock_item.positions.select { it.available >= line.quantity }.max_by(&:available)&.location
      raise Stock::Ledger::Refused, "Only #{line.stock_item.totals.available} available in one place." unless location

      hold = ledger.hold!(quantity: line.quantity, location: location, expires_at: hold_expires_at, buyer: buyer, reference: reference)
      line.update!(stock_hold: hold)
    end

    def let_go!(line, member)
      Stock::Ledger.new(line.stock_item, member: member).let_go!(line.stock_hold)
    end
end
