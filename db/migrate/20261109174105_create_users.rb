class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.datetime :email_verified_at
      t.boolean :platform_operator, null: false, default: false

      # Two-step sign-in (TOTP). The secret is encrypted with Active Record encryption.
      t.string :otp_secret
      t.datetime :otp_enabled_at
      t.datetime :otp_last_used_at

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
