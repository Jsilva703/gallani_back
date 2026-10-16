class CreateFinancialEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :financial_entries do |t|
      t.string :entry_type, null: false
      t.string :description, null: false
      t.references :appointment, foreign_key: true, index: false
      t.references :customer, foreign_key: true
      t.references :professional, foreign_key: true
      t.references :service, foreign_key: true
      t.string :payment_method
      t.string :category
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :date, null: false

      t.timestamps
    end

    add_index :financial_entries, :appointment_id,
              unique: true,
              where: "appointment_id IS NOT NULL",
              name: "index_financial_entries_unique_appointment"

    add_index :financial_entries, %i[date entry_type]
  end
end
