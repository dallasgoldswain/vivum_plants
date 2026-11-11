class AddWhatsNewSeenAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :whats_new_seen_at, :datetime
  end
end
