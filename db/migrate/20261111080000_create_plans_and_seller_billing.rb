class CreatePlansAndSellerBilling < ActiveRecord::Migration[8.1]
  def change
    # Plan data (SB01, D65): prices and limits change without a release. One boolean column
    # per entitlement named in config/features.yml.
    create_table :plans do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :name, null: false
      t.integer :monthly_price_cents, null: false
      t.integer :member_limit, null: false
      t.integer :photo_limit, null: false
      t.integer :ai_extractions_per_month, null: false
      t.boolean :paid_branding, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO plans (key, name, monthly_price_cents, member_limit, photo_limit, ai_extractions_per_month, paid_branding, created_at, updated_at)
          VALUES ('starter', 'Starter', 19900, 2, 2000, 1000, false, now(), now()),
                 ('pro', 'Pro', 44900, 5, 10000, 5000, true, now(), now())
        SQL
      end
    end

    # Billing mode (SB03, D64): pilot and comp are free; paid needs Paystack (later).
    add_column :sellers, :billing_mode, :string, null: false, default: "pilot"
    add_reference :sellers, :plan, foreign_key: true
    add_column :sellers, :free_until, :date

    reversible do |dir|
      dir.up { execute "UPDATE sellers SET plan_id = (SELECT id FROM plans WHERE key = 'pro')" }
    end
    change_column_null :sellers, :plan_id, false
  end
end
