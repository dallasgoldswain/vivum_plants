class User < ApplicationRecord
  OTP_ISSUER = "VIVUM"
  BACKUP_CODE_COUNT = 10

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :sellers, through: :memberships
  has_many :otp_backup_codes, dependent: :delete_all

  encrypts :otp_secret

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true

  # Token is invalidated once the address is verified or changed.
  generates_token_for :email_verification, expires_in: 2.days do
    [ email_address, email_verified_at ]
  end

  def email_verified?
    email_verified_at.present?
  end

  def verify_email!
    update!(email_verified_at: Time.current) unless email_verified?
  end

  # --- Two-step sign-in -------------------------------------------------------

  # Platform operators and seller owners control flags, payments and staff, so
  # they must use a second step. Anyone else may opt in.
  def two_factor_required?
    platform_operator? || memberships.owner.exists?
  end

  def two_factor_enabled?
    otp_enabled_at.present?
  end

  def self.generate_otp_secret
    ROTP::Base32.random
  end

  def self.otp_provisioning_uri(secret, email_address)
    ROTP::TOTP.new(secret, issuer: OTP_ISSUER).provisioning_uri(email_address)
  end

  def self.valid_otp_for_secret?(secret, code)
    ROTP::TOTP.new(secret).verify(code.to_s.gsub(/\s/, ""), drift_behind: 15).present?
  end

  # Turns on two-step sign-in and returns fresh plaintext backup codes, shown once.
  def enable_two_factor!(secret)
    transaction do
      update!(otp_secret: secret, otp_enabled_at: Time.current, otp_last_used_at: nil)
      regenerate_backup_codes!
    end
  end

  def disable_two_factor!
    transaction do
      otp_backup_codes.delete_all
      update!(otp_secret: nil, otp_enabled_at: nil, otp_last_used_at: nil)
    end
  end

  def regenerate_backup_codes!
    otp_backup_codes.delete_all
    Array.new(BACKUP_CODE_COUNT) { SecureRandom.alphanumeric(10).downcase }.each do |code|
      otp_backup_codes.create!(code: code)
    end
  end

  # Accepts a current TOTP code (each time step once only) or an unused backup code.
  def verify_second_factor(code)
    return false unless two_factor_enabled?

    verify_totp(code) || OtpBackupCode.redeem(self, code)
  end

  private
    def verify_totp(code)
      with_lock do
        timestamp = ROTP::TOTP.new(otp_secret).verify(
          code.to_s.gsub(/\s/, ""), drift_behind: 15, after: otp_last_used_at
        )
        next false unless timestamp

        update!(otp_last_used_at: Time.at(timestamp))
        true
      end
    end
end
