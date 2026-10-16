class CreateProfessionalServices < ActiveRecord::Migration[7.1]
  def change
    create_table :professional_services do |t|
      t.references :professional, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true

      t.timestamps
    end

    add_index :professional_services,
              %i[professional_id service_id],
              unique: true,
              name: "index_professional_services_unique"
  end
end
