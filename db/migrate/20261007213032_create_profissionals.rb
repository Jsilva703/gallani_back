class CreateProfessionals < ActiveRecord::Migration[7.1]
  def change
    create_table :professionals do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :professionals, :phone, unique: true
  end
end