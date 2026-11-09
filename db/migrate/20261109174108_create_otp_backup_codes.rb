class CreateOtpBackupCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_backup_codes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :code_digest, null: false
      t.datetime :used_at

      t.timestamps
    end
  end
end
