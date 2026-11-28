require "prawn"
require "prawn/table"

# A document as a printable A4 PDF (RC01, D191), drawn from its frozen copy only. Prawn's
# built-in fonts cover Windows-1252, so other characters are swapped or dropped.
class OrderDocument::Pdf
  REPLACEMENTS = { "−" => "-", "×" => "x", "·" => "-" }.freeze

  def initialize(document)
    @document = document
    @details = document.details
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 48, info: { Title: text(title) }).tap do |pdf|
      header(pdf)
      parties(pdf)
      @document.credit_note? ? credit_body(pdf) : receipt_body(pdf)
      pdf.move_down 24
      pdf.text text("Issued #{@document.issued_at.to_date.strftime('%-d %B %Y')} for order #{@details['order']}."), size: 9, color: "555555"
    end.render
  end

  private
    def title = "#{@document.title} #{@document.reference}"

    # The logo it was issued with (D255), fitted into a box at its own shape (D251).
    def header(pdf)
      if (logo = logo_data)
        pdf.image StringIO.new(logo), fit: [ 180, 72 ]
        pdf.move_down 12
      end
      pdf.text text(@document.title.upcase), size: 18, style: :bold
      pdf.text text(@document.reference), size: 12
      pdf.move_down 16
    end

    def parties(pdf)
      seller = @details["seller"]
      from = [ seller["legal_name"] || seller["name"], (seller["name"] if seller["legal_name"]), seller["address"], seller["phone"], seller["email"],
               *Array(seller["links"]).map { "#{it['name']} #{it['text']}" }, ("VAT number #{seller['vat_number']}" if vat?) ].compact_blank
      buyer = [ @details.dig("buyer", "name"), *Array(@details.dig("buyer", "address")) ].compact_blank
      pdf.table([ [ text("From\n" + from.join("\n")), text("To\n" + buyer.join("\n")) ] ], width: pdf.bounds.width, cell_style: { borders: [], padding: [ 0, 12, 0, 0 ], size: 10 })
      pdf.move_down 20
      pdf.text text("Against #{@details['against']}"), size: 10 if @document.credit_note?
    end

    def receipt_body(pdf)
      rows = [ %w[ Item Qty Price Total ] ]
      @details["lines"].each { rows << [ text("#{it['description']} (#{it['code']})"), it["quantity"].to_s, rands(it["unit_price_cents"]), rands(it["total_cents"]) ] }
      rows << [ "Shipping", "", "", rands(@details["shipping_cents"]) ] if @details["shipping_cents"].to_i.positive?
      rows << [ text("Discount (#{@details['discount_reason']})"), "", "", "-#{rands(@details['discount_cents'])}" ] if @details["discount_cents"].to_i.positive?
      pdf.table(rows, header: true, width: pdf.bounds.width, column_widths: { 1 => 50, 2 => 80, 3 => 80 }, cell_style: { size: 10, borders: [ :bottom ], border_color: "DDDDDD" }) do
        row(0).font_style = :bold
        columns(1..3).align = :right
      end
      totals(pdf)
      pdf.move_down 12
      @details["payments"].each do |payment|
        pdf.text text("Paid #{rands(payment['amount_cents'])} by #{payment['method']} on #{payment['paid_on']}#{" (#{payment['reference']})" if payment['reference']}"), size: 9
      end
    end

    def credit_body(pdf)
      pdf.text text("Reason: #{@document.reason}"), size: 10
      refund = @details["refund"]
      pdf.text text("Refunded by #{refund['method']} on #{refund['paid_on']}#{" (#{refund['reference']})" if refund['reference']}"), size: 10
      pdf.move_down 12
      totals(pdf)
    end

    def totals(pdf)
      rows = [ [ "Total", rands(@document.total_cents) ] ]
      rows << [ text("Includes VAT at #{@document.vat_rate.to_i}%"), rands(@document.vat_cents) ] if vat?
      pdf.move_down 8
      pdf.table(rows, position: :right, cell_style: { size: 11, borders: [], padding: [ 2, 0, 2, 24 ] }) do
        row(0).font_style = :bold
        column(1).align = :right
      end
    end

    def logo_data
      blob = ActiveStorage::Blob.find_by(id: @details.dig("seller", "logo_blob_id")) if @details.dig("seller", "logo_blob_id")
      blob&.download
    rescue ActiveStorage::FileNotFoundError
      nil
    end

    def vat? = @document.vat_rate.present?

    def rands(cents) = text(ActiveSupport::NumberHelper.number_to_currency(cents.to_i / 100.0, unit: "R", delimiter: " ", precision: 2, format: "%u%n"))

    def text(value)
      REPLACEMENTS.reduce(value.to_s) { |memo, (from, to)| memo.gsub(from, to) }.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "").encode("UTF-8")
    end
end
