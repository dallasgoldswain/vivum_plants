# This migration comes from refer (originally 20261007000000)
class AddUniqueIndexToReferReferralsReferee < ActiveRecord::Migration[7.1]
  def change
    remove_index :refer_referrals, [ :referee_type, :referee_id ]
    add_index :refer_referrals, [ :referee_type, :referee_id ], unique: true
  end
end
