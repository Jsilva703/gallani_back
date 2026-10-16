class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.date :date, null: false
      t.time :time, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_index :appointments,
              %i[professional_id date time],
              unique: true,
              where: "status IN ('scheduled', 'confirmed')",
              name: "index_appointments_active_slot_unique"

    add_index :appointments, %i[date status]
  end
end
