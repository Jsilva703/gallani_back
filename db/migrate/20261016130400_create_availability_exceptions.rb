class CreateAvailabilityExceptions < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_exceptions do |t|
      t.references :professional, null: false, foreign_key: true
      t.date :date, null: false
      t.string :times, array: true, default: [], null: false

      t.timestamps
    end

    add_index :availability_exceptions,
              %i[professional_id date],
              unique: true,
              name: "index_availability_exceptions_unique"
  end
end
