# Sell → Stock → Import (IM01, IM02, D199–D208): upload a CSV or .xlsx, check the preview,
# then commit it once. Owners and managers only, since rows carry prices and costs.
class Sell::StockImportsController < Sell::BaseController
  requires_capability "seller.csv_import"
  before_action { authorize! StockItem, to: :create? }
  before_action :set_import, only: %i[ show commit reverse ]

  def index
    @locations = Current.seller.stock_locations.active.by_name
    @imports = Current.seller.stock_imports.newest_first.includes(:created_by).limit(50)
  end

  def template
    send_data StockImport::Reader.template, filename: "vivum-stock-import-template.csv", type: "text/csv"
  end

  def create
    location = Current.seller.stock_locations.active.find_by(id: params[:stock_location_id])
    import = StockImport.preview!(seller: Current.seller, file: params[:file], location: location, member: Current.user, add_to_existing: params[:add_to_existing] == "1")
    redirect_to sell_stock_import_path(import)
  rescue StockImport::Refused => error
    redirect_to sell_stock_imports_path, alert: error.message
  end

  def show
    respond_to do |format|
      format.html
      format.csv do
        csv, name = params[:kind] == "report" ? [ @import.report_csv, "report" ] : [ @import.errors_csv, "errors" ]
        send_data csv, filename: "#{@import.reference}-#{name}.csv", type: "text/csv"
      end
    end
  end

  def commit
    @import.commit!(member: Current.user, confirm_duplicate: params[:confirm_duplicate] == "1")
    redirect_to sell_stock_import_path(@import), notice: "#{@import.reference} imported #{helpers.pluralize(@import.units, 'plant')}."
  rescue StockImport::Refused => error
    redirect_to sell_stock_import_path(@import), alert: error.message
  end

  def reverse
    @import.reverse!(member: Current.user)
    redirect_to sell_stock_import_path(@import), notice: "#{@import.reference} reversed."
  rescue StockImport::Refused => error
    redirect_to sell_stock_import_path(@import), alert: error.message
  end

  private
    def set_import
      @import = Current.seller.stock_imports.find(params[:id])
    end
end
