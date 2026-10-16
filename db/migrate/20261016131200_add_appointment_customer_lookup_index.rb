class AddAppointmentCustomerLookupIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :appointments,
              %i[customer_id status date time],
              name: "index_appointments_on_customer_status_date_time"
  end
end
