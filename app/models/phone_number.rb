# Phone numbers in E.164 (D171). South African local numbers (082 123 4567) become
# +27821234567; international numbers need a leading + or 00.
module PhoneNumber
  E164 = /\A\+[1-9]\d{7,14}\z/

  def self.normalise(value)
    digits = value.to_s.gsub(/[\s\-().]/, "")
    return if digits.empty?

    number =
      if digits.start_with?("+") then digits
      elsif digits.start_with?("00") then "+#{digits.delete_prefix('00')}"
      elsif digits.match?(/\A0\d{9}\z/) then "+27#{digits.delete_prefix('0')}"
      elsif digits.match?(/\A27\d{9}\z/) then "+#{digits}"
      else digits
      end
    number.match?(E164) ? number : digits
  end

  def self.valid?(value) = value.to_s.match?(E164)

  # +27821234567 → +27 82 *** **67, for pages a buyer opens.
  def self.mask(value)
    return "" if value.blank?

    "#{value[0, 3]} #{value[3, 2]} *** **#{value[-2, 2]}"
  end

  # +27821234567 → +27 82 123 4567 for South African numbers; others unchanged.
  def self.format(value)
    return "" if value.blank?
    return value unless value.match?(/\A\+27\d{9}\z/)

    "+27 #{value[3, 2]} #{value[5, 3]} #{value[8, 4]}"
  end
end
