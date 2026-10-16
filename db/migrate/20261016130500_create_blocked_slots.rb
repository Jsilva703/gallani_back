class CreateBlockedSlots < ActiveRecord::Migration[7.1]
  def change
    create_table :blocked_slots do |t|
      t.references :professional, null: false, foreign_key: true
      t.date :date, null: false
      t.time :time
      t.text :reason

      t.timestamps
    end

    add_index :blocked_slots,
              %i[professional_id date time],
              unique: true,
              where: "time IS NOT NULL",
              name: "index_blocked_slots_unique_time"

    add_index :blocked_slots,
              %i[professional_id date],
              unique: true,
              where: "time IS NULL",
              name: "index_blocked_slots_unique_day"
  end
end
