class CreateAvailabilitySlots < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_slots do |t|
      t.references :professional, null: false, foreign_key: true
      t.integer :weekday, null: false
      t.time :time, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :availability_slots,
              %i[professional_id weekday time],
              unique: true,
              name: "index_availability_slots_unique"
  end
end
