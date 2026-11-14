# Moves a plant from a member's collection into a seller's stock as a linked specimen (SE04,
# D162): names copied, one received at a location, the cover photo copied, and the plant's
# status set to moved to stock, keeping its history.
class Stock::Transfer
  class Refused < StandardError; end

  def self.from_plant!(plant, seller:, location:, member:, price: nil)
    raise Refused, "Only active plants can move to stock." unless plant.active?
    raise Refused, "This record holds #{plant.quantity} plants. Split it first so each specimen is one plant." if plant.quantity.to_i > 1
    raise Refused, "It's already in stock." if StockItem.active.exists?(plant: plant)
    raise Refused, "Choose a location of #{seller.name}." unless location&.seller_id == seller.id

    StockItem.transaction do
      item = seller.stock_items.create!(kind: "specimen", name: plant.display_name, cultivar: plant.cultivar, botanical_name: plant.botanical_name, price: price, plant: plant, moved_by: member)
      Stock::Ledger.new(item, member: member).receive!(quantity: 1, location: location, reason: "From #{plant.record_id} in a collection")
      copy_cover_photo(plant, item, member)
      plant.change_status!("moved_to_stock", reason: "Moved to #{seller.name} stock (#{item.code})")
      item
    end
  end

  def self.copy_cover_photo(plant, item, member)
    photo = plant.cover_photo or return
    copy = item.photos.new(user: member, caption: photo.caption, taken_on: photo.taken_on)
    copy.image.attach(io: StringIO.new(photo.image.download), filename: photo.image.filename.to_s, content_type: photo.image.content_type)
    copy.save!
  end
end
