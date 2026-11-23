require "csv"

# A stock import (IM01, IM02, D199–D208), numbered I-0001 per seller. Uploading reads the
# file into rows, each with its errors and warnings, and writes nothing to stock. Commit
# checks every row again and creates items and receives stock through Stock::Ledger in one
# transaction, once. A committed import can be reversed once, all or nothing, while every
# imported unit is still available where it arrived.
class StockImport < ApplicationRecord
  class Refused < StandardError; end

  STATES = %w[ previewed imported reversed expired ].freeze
  LIFETIME = 24.hours

  belongs_to :seller
  belongs_to :stock_location
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :imported_by, class_name: "User", optional: true
  belongs_to :reversed_by, class_name: "User", optional: true

  enum :state, STATES.index_by(&:itself), validate: true, default: "previewed"

  before_validation :assign_reference, on: :create

  scope :newest_first, -> { order(number: :desc) }
  scope :stale, -> { previewed.where(created_at: ...LIFETIME.ago) }

  def self.preview!(seller:, file:, location:, member:, add_to_existing: false)
    raise Refused, "Choose a location for rows that don't name one." unless location && location.seller_id == seller.id && location.archived_at.nil?

    reader = StockImport::Reader.new(file)
    rows = reader.rows
    import = seller.stock_imports.new(filename: reader.filename, checksum: reader.checksum, stock_location: location, add_to_existing: add_to_existing, rows: rows, created_by: member)
    import.check_rows
    import.save!
    import
  rescue StockImport::Reader::Invalid => error
    raise Refused, error.message
  end

  # Previews left for a day are dropped with their rows (D207).
  def self.expire_stale!
    stale.update_all(state: "expired", rows: [], updated_at: Time.current)
  end

  def expires_at = created_at + LIFETIME
  def open? = previewed? && expires_at.future?
  def errors? = rows.any? { it["errors"].present? }
  def error_count = rows.sum { it["errors"].to_a.size }
  def new_rows = rows.reject { it["item_id"] }
  def existing_rows = rows.select { it["item_id"] }
  def units = rows.sum { it["quantity"].to_i }

  # An earlier committed import of the same file (D205).
  def duplicate_of
    seller.stock_imports.imported.where(checksum: checksum).where.not(id: id).newest_first.first
  end

  # Works out each row's errors and warnings against the seller's stock as it is now.
  def check_rows
    locations = seller.stock_locations.where(archived_at: nil).index_by { it.name.downcase }
    skus = rows.filter_map { it["sku"].presence&.downcase }.tally
    existing = skus.empty? ? {} : seller.stock_items.where("LOWER(code) IN (?)", skus.keys).index_by { it.code.downcase }
    self.rows = rows.map { check_row(it.except("errors", "warnings", "item_id", "location_id"), locations, skus, existing) }
  end

  def commit!(member:, confirm_duplicate: false)
    outcome = transaction do
      lock!
      next :done unless previewed?
      raise Refused, "This preview has expired; upload the file again." unless open?
      if !confirm_duplicate && (earlier = duplicate_of)
        raise Refused, "#{earlier.reference} already imported this file on #{earlier.imported_at.to_date.to_fs(:long)}. Tick the box to import it again."
      end

      check_rows
      next :problems if errors?

      apply!(member)
      :done
    end
    if outcome == :problems
      update_columns(rows: rows, updated_at: Time.current)
      raise Refused, "Your stock has changed since the preview, and some rows can't be imported now. Fix the file and upload it again."
    end
    self
  rescue Stock::Ledger::Refused, ActiveRecord::RecordInvalid => error
    raise Refused, (error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : error.message)
  end

  # Takes the imported units back out (D206), or nothing if any of them has been held,
  # sold or moved since. Items the import created and left empty are archived.
  def reverse!(member:)
    transaction do
      lock!
      return self if reversed?
      raise Refused, "Only a completed import can be reversed." unless imported?

      items = StockItem.where(id: report.map { it["item_id"] }).order(:id).lock.index_by(&:id)
      locations = seller.stock_locations.where(id: report.map { it["location_id"] }).index_by(&:id)
      received = report.select { it["quantity"].to_i.positive? }.group_by { [ it["item_id"], it["location_id"] ] }

      blocked = received.filter_map do |(item_id, location_id), lines|
        item, location = items.fetch(item_id), locations.fetch(location_id)
        quantity = lines.sum { it["quantity"] }
        available = Stock::Ledger.new(item, member: member).position(location).available
        "#{item.code} at #{location.name} (#{available} of #{quantity} still available)" if available < quantity
      end
      raise Refused, "Nothing was reversed: some of the imported stock has been held, sold or moved. #{blocked.join('; ')}." if blocked.any?

      received.each do |(item_id, location_id), lines|
        Stock::Ledger.new(items.fetch(item_id), member: member).lose!(quantity: lines.sum { it["quantity"] }, location: locations.fetch(location_id), reason: "Import #{reference} reversed")
      end
      report.select { it["action"] == "created" }.map { items.fetch(it["item_id"]) }.uniq.each do |item|
        item.update!(archived_at: Time.current) if item.balances.sum("saleable + unavailable").zero? && !item.holds.current.exists?
      end
      update!(state: "reversed", reversed_at: Time.current, reversed_by: member)
      Audit.record("stock_import.reversed", actor: member, target: self, details: { reference: reference, units: report.sum { it["quantity"].to_i } })
      self
    end
  rescue Stock::Ledger::Refused => error
    raise Refused, error.message
  end

  def errors_csv
    CSV.generate do |csv|
      csv << %w[ line sku name problem ]
      rows.each { |row| row["errors"].to_a.each { csv << [ row["line"], row["sku"], row["name"], it ] } }
    end
  end

  def report_csv
    CSV.generate do |csv|
      csv << %w[ line action sku name location quantity ]
      report.each { csv << it.values_at("line", "action", "sku", "name", "location", "quantity") }
    end
  end

  private
    def check_row(row, locations, skus, existing)
      errors = []
      warnings = []
      errors << "This row has more values than the file has columns." if row["extra_values"]

      kind = row["type"].to_s.downcase
      errors << "Type must be specimen or batch." unless StockItem::KINDS.include?(kind)
      quantity = row["quantity"].to_s
      errors << "Quantity must be a whole number, 0 or more." unless quantity.match?(/\A\d+\z/)
      quantity = quantity.to_i
      price_cents, cost_cents = %w[ price cost ].map do |column|
        next if row[column].blank?

        Order.cents(row[column]).tap { errors << "#{column.capitalize} \"#{row[column]}\" isn't an amount in rands." if it.negative? }
      end

      location = row["location"].present? ? locations[row["location"].downcase] : (stock_location unless stock_location.archived_at)
      errors << (row["location"].present? ? "There's no location called \"#{row["location"]}\"; add it under Locations first." : "The default location is archived.") unless location

      sku = row["sku"].to_s
      errors << "SKU #{sku} appears more than once in the file." if sku.present? && skus[sku.downcase].to_i > 1

      if (item = existing[sku.downcase])
        row["item_id"] = item.id
        if !add_to_existing
          errors << "SKU #{item.code} is already in your stock. Tick \"Add to existing\" to add this quantity to it."
        elsif item.archived?
          errors << "#{item.code} is archived."
        elsif item.specimen?
          errors << "#{item.code} is a specimen, so it can't take more stock."
        elsif quantity.zero?
          errors << "Quantity must be 1 or more to add stock to #{item.code}."
        else
          warnings.concat(differences(row, item, kind, price_cents))
        end
      else
        new_item = seller.stock_items.new(new_item_attributes(row, kind, price_cents, cost_cents))
        new_item.valid?
        errors.concat(new_item.errors.full_messages_for(:name) + new_item.errors.full_messages_for(:code) + %i[ cultivar botanical_name size notes ].flat_map { new_item.errors.full_messages_for(it) })
        errors << "A specimen is one plant, so its quantity must be 1." if kind == "specimen" && quantity != 1
      end

      row.merge("location_id" => location&.id, "errors" => errors.uniq, "warnings" => warnings)
    end

    def differences(row, item, kind, price_cents)
      changes = []
      changes << "name" if row["name"].present? && row["name"].casecmp?(item.name) == false
      changes << "cultivar" if row["cultivar"].present? && row["cultivar"].casecmp?(item.cultivar.to_s) == false
      changes << "type" if StockItem::KINDS.include?(kind) && kind != item.kind
      changes << "price" if price_cents && price_cents != item.price_cents
      return [] if changes.empty?

      [ "The #{changes.to_sentence} #{changes.one? ? 'differs' : 'differ'} from #{item.code}; only the quantity is added." ]
    end

    def new_item_attributes(row, kind = row["type"].to_s.downcase, price_cents = row["price"].presence && Order.cents(row["price"]), cost_cents = row["cost"].presence && Order.cents(row["cost"]))
      { kind: kind.presence_in(StockItem::KINDS), name: row["name"], cultivar: row["cultivar"], botanical_name: row["botanical_name"], size: row["size"], notes: row["notes"], code: row["sku"].presence, price_cents: price_cents, cost_cents: cost_cents }
    end

    def apply!(member)
      items = StockItem.where(id: existing_rows.map { it["item_id"] }).order(:id).lock.index_by(&:id)
      locations = seller.stock_locations.where(id: rows.map { it["location_id"] }).index_by(&:id)
      self.report = rows.map do |row|
        location = locations.fetch(row["location_id"])
        item = items[row["item_id"]] || seller.stock_items.create!(new_item_attributes(row))
        quantity = row["quantity"].to_i
        Stock::Ledger.new(item, member: member).receive!(quantity: quantity, location: location, reason: "Import #{reference}") if quantity.positive?
        { "line" => row["line"], "action" => row["item_id"] ? "added" : "created", "item_id" => item.id, "sku" => item.code, "name" => item.name, "location_id" => location.id, "location" => location.name, "quantity" => quantity }
      end
      update!(state: "imported", imported_at: Time.current, imported_by: member)
      Audit.record("stock_import.imported", actor: member, target: self, details: { reference: reference, created: report.count { it["action"] == "created" }, added: report.count { it["action"] == "added" }, units: units })
    end

    def assign_reference
      return if reference.present? || seller.nil?

      self.number = seller.class.connection.select_value(
        seller.class.sanitize_sql_array([ "UPDATE sellers SET last_import_number = last_import_number + 1 WHERE id = ? RETURNING last_import_number", seller_id ])
      ).to_i
      self.reference = format("I-%04d", number)
    end
end
