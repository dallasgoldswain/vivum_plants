require "test_helper"

class StockImportsTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.csv_import help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
  end

  test "an owner downloads the template, previews, imports once and reverses" do
    sign_in_as users(:owner)
    get sell_stock_items_path
    assert_select "a[href=?]", sell_stock_imports_path, text: "Import"
    get template_sell_stock_imports_path
    assert_match "SKU,Name,Cultivar,Type,Quantity", response.body

    assert_no_difference -> { StockItem.count } do
      post sell_stock_imports_path, params: { file: upload("sku,name,type,quantity,price\nH1,Hoya,batch,3,45\n"), stock_location_id: @greenhouse.id }
    end
    import = @seller.stock_imports.sole
    assert_redirected_to sell_stock_import_path(import)
    follow_redirect!
    assert_select "#row_2", /Hoya/
    assert_select "#summary input[type=submit][value=?]", "Import 3 plants"

    assert_difference -> { StockItem.count } => 1 do
      post commit_sell_stock_import_path(import)
      post commit_sell_stock_import_path(import)
    end
    follow_redirect!
    assert_select "#report", /1 item created/
    get sell_stock_import_path(import, format: :csv, kind: "report")
    assert_match "2,created,H1,Hoya,Greenhouse,3", response.body

    post reverse_sell_stock_import_path(import)
    assert import.reload.reversed?
    assert @seller.stock_items.find_by!(code: "H1").archived?
  end

  test "a file with problems can't be imported and its problems download" do
    sign_in_as users(:owner)
    post sell_stock_imports_path, params: { file: upload("name,type,quantity\nHoya,tree,1\n"), stock_location_id: @greenhouse.id }
    import = @seller.stock_imports.sole
    get sell_stock_import_path(import)
    assert_select "#problems", /1 problem/
    assert_select "#summary input[type=submit]", 0
    get sell_stock_import_path(import, format: :csv)
    assert_match "2,,Hoya,Type must be specimen or batch.", response.body
  end

  test "an unreadable file is refused with a message" do
    sign_in_as users(:owner)
    post sell_stock_imports_path, params: { file: upload("name\nHoya\n"), stock_location_id: @greenhouse.id }
    assert_redirected_to sell_stock_imports_path
    assert_match "needs a type column", flash[:alert]
    assert_empty @seller.stock_imports
  end

  test "host/packers can't import and other sellers' imports are hidden" do
    sign_in_as users(:packer)
    get sell_stock_imports_path
    assert_redirected_to root_path
    get sell_stock_items_path
    assert_select "a[href=?]", sell_stock_imports_path, 0

    other = sellers(:aroid_attic)
    import = other.stock_imports.create!(filename: "x.csv", checksum: "x", stock_location: other.stock_locations.create!(name: "Attic"), created_by: users(:manager))
    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    get sell_stock_import_path(import)
    assert_response :not_found
  end

  private
    def upload(content)
      file = Tempfile.new([ "import", ".csv" ])
      file.write(content)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "text/csv", original_filename: "stock.csv")
    end
end
