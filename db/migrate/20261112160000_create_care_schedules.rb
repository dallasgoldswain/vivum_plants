# Reminders: schedules and their tasks, one open task per schedule (CA02, CA03, D111–D120).
class CreateCareSchedules < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :time_zone, :string

    create_table :care_schedules do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :label
      t.string :note
      t.integer :interval
      t.string :interval_unit
      t.string :mode, null: false, default: "after_completion"
      t.date :starts_on, null: false
      t.string :status, null: false, default: "active"
      t.boolean :paused_by_status, null: false, default: false
      t.timestamps
      t.check_constraint "interval IS NULL OR (interval > 0 AND interval_unit IN ('day', 'week', 'month'))", name: "care_schedules_interval_valid"
    end

    create_table :care_tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plant, null: false, foreign_key: true
      t.references :care_schedule, null: false, foreign_key: true
      t.date :due_on, null: false
      t.boolean :due_on_changed_by_hand, null: false, default: false
      t.date :snoozed_until
      t.string :state, null: false, default: "open"
      t.datetime :resolved_at
      t.date :resolved_on
      t.timestamps
      t.index :care_schedule_id, unique: true, where: "state = 'open'", name: "index_care_tasks_one_open_per_schedule"
      t.index %i[ user_id state due_on ]
    end

    add_reference :care_events, :care_task, foreign_key: { on_delete: :nullify }, index: { unique: true }
  end
end
