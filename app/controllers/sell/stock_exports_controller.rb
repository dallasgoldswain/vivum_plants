require "csv"

# The business's stock as CSV (D163): items with their totals, or the movement ledger.
# Owners and managers only, since it includes prices and costs.
class Sell::StockExportsController < Sell::BaseController
  requires_capability "seller.stock"

  def show
    authorize! StockItem, to: :create?
    if params[:kind] == "listings"
      send_data listings_csv, filename: "listings-#{Date.current.iso8601}.csv", type: "text/csv"
    elsif params[:kind] == "movements"
      send_data movements_csv, filename: "stock-movements-#{Date.current.iso8601}.csv", type: "text/csv"
    else
      send_data items_csv, filename: "stock-#{Date.current.iso8601}.csv", type: "text/csv"
    end
  end

  private
    def items_csv
      CSV.generate do |csv|
        csv << %w[ code kind name cultivar botanical_name size price cost currency saleable unavailable held available archived ]
        Current.seller.stock_items.includes(:balances).by_name.each do |item|
          totals = item.totals
          csv << [ item.code, item.kind, item.name, item.cultivar, item.botanical_name, item.size, item.price, item.cost, item.currency, totals.saleable, totals.unavailable, totals.held, totals.available, item.archived? ]
        end
      end
    end

    def listings_csv
      CSV.generate do |csv|
        csv << %w[ reference code title price listed_quantity available state created_at ended_at ]
        Current.seller.listings.includes(stock_item: :balances).order(:number).each do |listing|
          csv << [ listing.reference, listing.stock_item.code, listing.title, listing.price, listing.listed_quantity, listing.available, listing.display_state, listing.created_at.iso8601, listing.ended_at&.iso8601 ]
        end
      end
    end

    def movements_csv
      CSV.generate do |csv|
        csv << %w[ occurred_at code kind quantity bucket location to_location reason member ]
        Current.seller.stock_movements.includes(:stock_item, :stock_location, :to_location, :member).order(:occurred_at, :id).each do |movement|
          csv << [ movement.occurred_at.iso8601, movement.stock_item.code, movement.kind, movement.quantity, movement.bucket, movement.stock_location.name, movement.to_location&.name, movement.reason, movement.member&.email_address ]
        end
      end
    end
end
