class AddIdentityToSellers < ActiveRecord::Migration[8.1]
  def change
    change_table :sellers, bulk: true do |t|
      t.string :instagram_url
      t.string :facebook_url
      t.string :youtube_url
      t.string :whatsapp_number
      t.boolean :show_instagram, default: true, null: false
      t.boolean :show_facebook, default: true, null: false
      t.boolean :show_youtube, default: true, null: false
      t.boolean :show_whatsapp, default: true, null: false
      t.string :card_link
    end

    change_table :sale_cards, bulk: true do |t|
      t.string :business_label
      t.bigint :logo_blob_id
    end

    # Cards made before B29 show the business name alone.
    reversible do |dir|
      dir.up { execute "UPDATE sale_cards SET business_label = sellers.name FROM listings, sellers WHERE listings.id = sale_cards.listing_id AND sellers.id = listings.seller_id" }
    end
  end
end
