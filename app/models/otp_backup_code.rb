class OtpBackupCode < ApplicationRecord
  belongs_to :user

  has_secure_password :code, validations: false

  scope :unused, -> { where(used_at: nil) }

  # Marks a matching unused code as used. The conditional update means two
  # simultaneous requests cannot both redeem the same code.
  def self.redeem(user, code)
    normalized = code.to_s.gsub(/\s|-/, "").downcase
    return false if normalized.blank?

    match = user.otp_backup_codes.unused.find { |backup| backup.authenticate_code(normalized) }
    return false unless match

    unused.where(id: match.id).update_all(used_at: Time.current) == 1
  end
end
