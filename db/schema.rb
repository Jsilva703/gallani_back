# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_10_16_131200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_tokens", force: :cascade do |t|
    t.string "label", null: false
    t.string "token_digest", null: false
    t.string "scope", default: "integration", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope", "active"], name: "index_api_tokens_on_scope_and_active"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "professional_id", null: false
    t.bigint "service_id", null: false
    t.date "date", null: false
    t.time "time", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["customer_id", "status", "date", "time"], name: "index_appointments_on_customer_status_date_time"
    t.index ["date", "status"], name: "index_appointments_on_date_and_status"
    t.index ["professional_id", "date", "time"], name: "index_appointments_active_slot_unique", unique: true, where: "((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('confirmed'::character varying)::text]))"
    t.index ["professional_id"], name: "index_appointments_on_professional_id"
    t.index ["service_id"], name: "index_appointments_on_service_id"
  end

  create_table "availability_exceptions", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.date "date", null: false
    t.string "times", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_id", "date"], name: "index_availability_exceptions_unique", unique: true
    t.index ["professional_id"], name: "index_availability_exceptions_on_professional_id"
  end

  create_table "availability_slots", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.integer "weekday", null: false
    t.time "time", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_id", "weekday", "time"], name: "index_availability_slots_unique", unique: true
    t.index ["professional_id"], name: "index_availability_slots_on_professional_id"
  end

  create_table "blocked_slots", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.date "date", null: false
    t.time "time"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_id", "date", "time"], name: "index_blocked_slots_unique_time", unique: true, where: "(\"time\" IS NOT NULL)"
    t.index ["professional_id", "date"], name: "index_blocked_slots_unique_day", unique: true, where: "(\"time\" IS NULL)"
    t.index ["professional_id"], name: "index_blocked_slots_on_professional_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_customers_on_phone"
  end

  create_table "financial_entries", force: :cascade do |t|
    t.string "entry_type", null: false
    t.string "description", null: false
    t.bigint "appointment_id"
    t.bigint "customer_id"
    t.bigint "professional_id"
    t.bigint "service_id"
    t.string "payment_method"
    t.string "category"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_financial_entries_unique_appointment", unique: true, where: "(appointment_id IS NOT NULL)"
    t.index ["customer_id"], name: "index_financial_entries_on_customer_id"
    t.index ["date", "entry_type"], name: "index_financial_entries_on_date_and_entry_type"
    t.index ["professional_id"], name: "index_financial_entries_on_professional_id"
    t.index ["service_id"], name: "index_financial_entries_on_service_id"
  end

  create_table "professional_services", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_id", "service_id"], name: "index_professional_services_unique", unique: true
    t.index ["professional_id"], name: "index_professional_services_on_professional_id"
    t.index ["service_id"], name: "index_professional_services_on_service_id"
  end

  create_table "professionals", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_professionals_on_phone", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_user_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_user_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.boolean "active", default: true, null: false
    t.bigint "professional_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["professional_id"], name: "index_users_on_professional_id"
    t.index ["professional_id"], name: "index_users_unique_professional", unique: true, where: "(professional_id IS NOT NULL)"
  end

  add_foreign_key "appointments", "customers"
  add_foreign_key "appointments", "professionals"
  add_foreign_key "appointments", "services"
  add_foreign_key "availability_exceptions", "professionals"
  add_foreign_key "availability_slots", "professionals"
  add_foreign_key "blocked_slots", "professionals"
  add_foreign_key "financial_entries", "appointments"
  add_foreign_key "financial_entries", "customers"
  add_foreign_key "financial_entries", "professionals"
  add_foreign_key "financial_entries", "services"
  add_foreign_key "professional_services", "professionals"
  add_foreign_key "professional_services", "services"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users", "professionals"
end
