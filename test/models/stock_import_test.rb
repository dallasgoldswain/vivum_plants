require "test_helper"

class StockImportTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @owner = users(:owner)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @shelf = @seller.stock_locations.create!(name: "Shop shelf")
  end

  test "a preview writes nothing to stock; commit creates items and receives stock once" do
    import = preview(<<~CSV)
      SKU,Name,Cultivar,Type,Quantity,Price,Location,Botanical name
      MON-01,Monstera,Thai Constellation,specimen,1,"1 200",,Monstera deliciosa
      ,Pothos,Marble Queen,batch,12,R85,shop shelf,
    CSV
    assert_not import.errors?
    assert_equal 0, @seller.stock_items.count

    assert_difference -> { @seller.stock_items.count } => 2, -> { StockMovement.count } => 2 do
      import.commit!(member: @owner)
      import.commit!(member: @owner)
    end
    monstera = @seller.stock_items.find_by!(code: "MON-01")
    assert_equal [ "specimen", 120000, "Monstera deliciosa" ], [ monstera.kind, monstera.price_cents, monstera.botanical_name ]
    assert_equal 1, monstera.totals.saleable
    pothos = @seller.stock_items.find_by!(name: "Pothos")
    assert_match(/\AS-\d{4}\z/, pothos.code)
    assert_equal 12, pothos.balances.find_by!(stock_location: @shelf).saleable
    assert_equal "Import #{import.reference}", pothos.movements.sole.reason
    assert_equal "I-0001", import.reference
    assert AuditEvent.exists?(action: "stock_import.imported", target_id: import.id)
  end

  test "row errors block the commit" do
    @seller.stock_items.create!(kind: "batch", name: "Fern", code: "FERN")
    import = preview(<<~CSV)
      sku,name,type,quantity,price,location
      A1,Alocasia,specimen,2,100,
      A1,Anthurium,batch,x,,
      FERN,Fern,batch,3,,
      ,,batch,1,abc,Attic
      B2,Begonia,tree,1,,,extra
    CSV
    assert import.errors?
    messages = import.rows.map { it["errors"] }
    assert_includes messages[0], "A specimen is one plant, so its quantity must be 1."
    assert_includes messages[0], "SKU A1 appears more than once in the file."
    assert_includes messages[1], "Quantity must be a whole number, 0 or more."
    assert_match "Tick \"Add to existing\"", messages[2].join
    assert_includes messages[3], "Name can't be blank"
    assert_includes messages[3], "Price \"abc\" isn't an amount in rands."
    assert_match "no location called \"Attic\"", messages[3].join
    assert_includes messages[4], "Type must be specimen or batch."
    assert_includes messages[4], "This row has more values than the file has columns."
    assert_match "line,sku,name,problem", import.errors_csv

    assert_no_difference -> { StockItem.count } do
      assert_raises(StockImport::Refused) { import.commit!(member: @owner) }
    end
  end

  test "add to existing only adds quantity and warns about differences" do
    fern = @seller.stock_items.create!(kind: "batch", name: "Fern", code: "FERN", price_cents: 5000)
    import = preview("sku,name,type,quantity,price\nfern,Boston fern,batch,4,60\n", add_to_existing: true)
    assert_not import.errors?
    assert_match "The name and price differ from FERN", import.rows.sole["warnings"].sole

    import.commit!(member: @owner)
    fern.reload
    assert_equal [ "Fern", 5000, 4 ], [ fern.name, fern.price_cents, fern.totals.saleable ]
    assert_equal "added", import.report.sole["action"]
  end

  test "commit rechecks rows and refuses a file already imported without confirmation" do
    csv = "sku,name,type,quantity\nX1,Hoya,batch,2\n"
    first = preview(csv)
    second = preview(csv)
    first.commit!(member: @owner)

    error = assert_raises(StockImport::Refused) { second.commit!(member: @owner) }
    assert_match "I-0001 already imported this file", error.message
    error = assert_raises(StockImport::Refused) { second.commit!(member: @owner, confirm_duplicate: true) }
    assert_match "Your stock has changed since the preview", error.message
    assert_match "already in your stock", second.reload.rows.sole["errors"].join
  end

  test "reversal undoes an untouched import, and refuses once any unit is held" do
    @seller.stock_items.create!(kind: "batch", name: "Fern", code: "FERN").then { Stock::Ledger.new(it, member: @owner).receive!(quantity: 2, location: @greenhouse) }
    import = preview("sku,name,type,quantity\nFERN,Fern,batch,3\nP1,Peperomia,batch,5\n", add_to_existing: true)
    import.commit!(member: @owner)
    peperomia = @seller.stock_items.find_by!(code: "P1")
    hold = Stock::Ledger.new(peperomia, member: @owner).hold!(quantity: 1, location: @greenhouse, expires_at: 1.day.from_now, held_for: "Sam")

    error = assert_raises(StockImport::Refused) { import.reverse!(member: @owner) }
    assert_match "P1 at Greenhouse (4 of 5 still available)", error.message
    assert_equal 5, peperomia.totals.saleable

    Stock::Ledger.new(peperomia, member: @owner).release!(hold)
    import.reverse!(member: @owner)
    assert import.reload.reversed?
    assert_equal 2, @seller.stock_items.find_by!(code: "FERN").totals.saleable
    assert_equal 0, peperomia.reload.totals.on_hand
    assert peperomia.archived?
    assert_not @seller.stock_items.find_by!(code: "FERN").archived?
  end

  test "reads xlsx files and rejects files it can't use" do
    package = Axlsx::Package.new
    package.workbook.add_worksheet { |sheet| sheet.add_row([ "Name", "Type", "Quantity", "Price" ]); sheet.add_row([ "Hoya", "batch", 3, 45.5 ]) }
    import = StockImport.preview!(seller: @seller, file: upload(package.to_stream.read, "stock.xlsx"), location: @greenhouse, member: @owner)
    assert_equal [ "Hoya", "3", "45.5" ], import.rows.sole.values_at("name", "quantity", "price")

    assert_raises(StockImport::Refused, match: /needs a type column and a quantity column/) { preview("name\nHoya\n") }
    assert_raises(StockImport::Refused, match: /isn't UTF-8/) { preview("name,type,quantity\nCaf\xE9,batch,1\n".b) }
    assert_raises(StockImport::Refused, match: /\.csv or \.xlsx/) { StockImport.preview!(seller: @seller, file: upload("x", "stock.txt"), location: @greenhouse, member: @owner) }
  end

  test "stale previews expire" do
    import = preview("name,type,quantity\nHoya,batch,1\n")
    import.update_column(:created_at, 25.hours.ago)
    StockImport.expire_stale!
    assert import.reload.expired?
    assert_empty import.rows
  end

  private
    def preview(csv, add_to_existing: false)
      StockImport.preview!(seller: @seller, file: upload(csv, "stock.csv"), location: @greenhouse, member: @owner, add_to_existing: add_to_existing)
    end

    def upload(content, name)
      file = Tempfile.new([ "import", File.extname(name) ], binmode: true)
      file.write(content)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "application/octet-stream", true, original_filename: name)
    end
end
