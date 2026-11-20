# A buyer's data request (PR05, D177): their data as JSON, or deletion. Deleting wipes
# contacts, addresses and consents, unlinks aliases and keeps an anonymised record so holds
# and the stock history read "Deleted buyer". Orders are seller records kept for 5 years with
# their own name and address copies (PR07, D188), so open ones must be closed first.
module Buyer::Erasure
  extend ActiveSupport::Concern

  def export_data
    {
      exported_at: Time.current.iso8601,
      responsible_party: seller.name,
      buyer: { name: name, phone: phone, email: email, contact_preference: contact_preference, verified_at: verified_at&.iso8601, verification_method: verification_method, created_at: created_at.iso8601 },
      addresses: addresses.map { it.slice(:label, :recipient, :street, :suburb, :city, :province, :postal_code, :default) },
      aliases: aliases.map { it.slice(:name, :group_name) },
      consents: consents.order(:created_at, :id).map { { purpose: it.purpose, version: it.version, granted: it.granted, source: it.source, method: it.method, given_at: it.given_at.iso8601 } },
      holds: holds.includes(:stock_item).order(:created_at).map { { item: it.stock_item.code, quantity: it.quantity, state: it.state, held_until: it.expires_at.iso8601, created_at: it.created_at.iso8601 } },
      orders: orders.includes(:lines).order(:number).map do |order|
        { number: order.reference, state: order.state, payment_state: order.payment_state, delivery_method: order.delivery_method, shipping_address: order.shipping_address, total_cents: order.total_cents, created_at: order.created_at.iso8601,
          lines: order.lines.map { { item: it.description, quantity: it.quantity, unit_price_cents: it.unit_price_cents, state: it.state } } }
      end
    }
  end

  def erase!
    raise ActiveRecord::RecordNotDestroyed.new("Cancel or fulfil #{name}'s open orders first.", self) if orders.open.exists?

    transaction do
      hold_ids = holds.ids
      StockHold.where(id: hold_ids).update_all(held_for: Buyer::DELETED_NAME)
      StockMovement.where(stock_hold_id: hold_ids).update_all(reason: Buyer::DELETED_NAME)
      addresses.delete_all
      consents.delete_all
      verifications.delete_all
      aliases.update_all(buyer_id: nil)
      update_columns(name: Buyer::DELETED_NAME, phone: nil, email: nil, verified_at: nil, verification_method: nil, deleted_at: Time.current, updated_at: Time.current)
      Audit.record("buyer.deleted", target: self)
    end
  end
end
