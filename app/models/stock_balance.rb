# What one item has at one location (D157): saleable and unavailable units on hand. Kept in
# step with the ledger inside the same transaction; the database refuses negatives.
class StockBalance < ApplicationRecord
  belongs_to :stock_item
  belongs_to :stock_location

  def on_hand = saleable + unavailable
end
