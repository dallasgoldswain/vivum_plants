require "csv"

# Reads an uploaded stock file (IM01, D202, D203, D207): a UTF-8 CSV or an Excel .xlsx,
# at most 2 MB and 2,000 rows. Headers match ignoring case, spaces and punctuation, so
# "Botanical name", "botanical_name" and "BOTANICAL NAME" are the same column. Problems
# with the file as a whole raise Invalid; problems with a row are left to StockImport.
class StockImport::Reader
  class Invalid < StandardError; end

  MAX_BYTES = 2.megabytes
  MAX_ROWS = 2_000
  COLUMNS = {
    "sku" => %w[ sku code ], "name" => %w[ name ], "cultivar" => %w[ cultivar ], "type" => %w[ type kind ],
    "quantity" => %w[ quantity qty ], "price" => %w[ price ], "location" => %w[ location ],
    "botanical_name" => %w[ botanicalname ], "size" => %w[ size ], "cost" => %w[ cost ], "notes" => %w[ notes ]
  }.freeze
  REQUIRED = %w[ name type quantity ].freeze
  TEMPLATE = %w[ SKU Name Cultivar Type Quantity Price Location Botanical\ name Size Cost Notes ].freeze

  def self.template
    CSV.generate do |csv|
      csv << TEMPLATE
      csv << [ "MON-01", "Monstera deliciosa", "Thai Constellation", "specimen", 1, "1200", "", "Monstera deliciosa", "15cm pot", "", "" ]
      csv << [ "", "Pothos", "Marble Queen", "batch", 12, "85", "", "Epipremnum aureum", "", "40", "" ]
    end
  end

  def initialize(file)
    @file = file
  end

  def filename = @file.original_filename.to_s.truncate(200)
  def checksum = Digest::SHA256.file(@file.path).hexdigest

  # One hash per filled-in row: its line in the file and the recognised columns as text.
  def rows
    header, *body = table
    raise Invalid, "That file is empty." if header.nil? || header.all? { cell(it).empty? }

    columns = header.map { column_for(it) }
    missing = REQUIRED - columns
    raise Invalid, "The file needs #{missing.map { "a #{it} column" }.to_sentence}. Download the template to see the headings." if missing.any?

    rows = body.each_with_index.filter_map do |values, index|
      next if values.all? { cell(it).empty? }

      row = { "line" => index + 2 }
      columns.each_with_index { |column, at| row[column] = cell(values[at]) if column }
      row["extra_values"] = true if values.drop(header.size).any? { cell(it).present? }
      row
    end
    raise Invalid, "That file has no rows to import." if rows.empty?
    raise Invalid, "That file has #{rows.size} rows; import at most #{MAX_ROWS} at a time." if rows.size > MAX_ROWS

    rows
  end

  private
    def table
      raise Invalid, "Choose a file to import." unless @file.respond_to?(:path) && @file.respond_to?(:original_filename)
      raise Invalid, "That file is over 2 MB; split it into smaller files." if @file.size > MAX_BYTES

      case File.extname(filename).downcase
      when ".csv" then read_csv
      when ".xlsx" then read_xlsx
      else raise Invalid, "Upload a .csv or .xlsx file."
      end
    end

    def read_csv
      text = File.read(@file.path, encoding: "bom|utf-8")
      raise Invalid, "That file isn't UTF-8. Save it as \"CSV UTF-8\" and upload it again." unless text.valid_encoding?

      CSV.parse(text)
    rescue CSV::MalformedCSVError => error
      raise Invalid, "That CSV can't be read (#{error.message})."
    end

    def read_xlsx
      sheet = Roo::Excelx.new(@file.path)
      return [] unless sheet.first_row

      (sheet.first_row..sheet.last_row).map { sheet.row(it) }
    rescue Invalid
      raise
    rescue StandardError
      raise Invalid, "That .xlsx file can't be read. Save it again from Excel or upload a CSV."
    end

    def column_for(heading)
      key = cell(heading).downcase.gsub(/[^a-z]/, "")
      COLUMNS.find { |_, names| names.include?(key) }&.first
    end

    # Spreadsheet numbers come back as floats: 12.0 is "12".
    def cell(value)
      case value
      when nil then ""
      when Float then (value % 1).zero? ? value.to_i.to_s : value.to_s
      else value.to_s.squish
      end
    end
end
