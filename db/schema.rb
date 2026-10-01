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

ActiveRecord::Schema[8.1].define(version: 2026_09_21_162605) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cash_closings", force: :cascade do |t|
    t.datetime "closed_at", null: false
    t.decimal "counted_cash", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "credit_total", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "difference", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "expected_cash", precision: 18, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "opened_at", null: false
    t.decimal "payments_total", precision: 18, scale: 2, default: "0.0", null: false
    t.integer "sales_count", default: 0, null: false
    t.string "terminal_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "voided_count", default: 0, null: false
    t.index ["closed_at"], name: "index_cash_closings_on_closed_at"
    t.index ["terminal_id", "closed_at"], name: "index_cash_closings_on_terminal_id_and_closed_at"
    t.index ["terminal_id"], name: "index_cash_closings_on_terminal_id"
    t.index ["user_id"], name: "index_cash_closings_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_categories_on_active_and_position"
    t.index ["code"], name: "index_categories_on_code", unique: true, where: "(code IS NOT NULL)"
    t.index ["discarded_at"], name: "index_categories_on_discarded_at"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "credits", force: :cascade do |t|
    t.decimal "amount", precision: 18, scale: 2, null: false
    t.decimal "balance", precision: 18, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.datetime "paid_at"
    t.bigint "sale_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "status"], name: "index_credits_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_credits_on_customer_id"
    t.index ["paid_at"], name: "index_credits_on_paid_at"
    t.index ["sale_id"], name: "index_credits_on_sale_id"
    t.index ["status"], name: "index_credits_on_status"
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address"
    t.datetime "created_at", null: false
    t.decimal "credit_balance", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "credit_limit", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "discarded_at"
    t.string "document_number"
    t.integer "document_type", default: 0, null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
    t.index ["document_number"], name: "index_customers_on_document_number", unique: true, where: "(document_number IS NOT NULL)"
    t.index ["name"], name: "index_customers_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["phone"], name: "index_customers_on_phone", where: "(phone IS NOT NULL)"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 18, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "credit_id", null: false
    t.bigint "customer_id", null: false
    t.text "notes"
    t.datetime "paid_at", null: false
    t.string "terminal_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["credit_id"], name: "index_payments_on_credit_id"
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["paid_at"], name: "index_payments_on_paid_at"
    t.index ["terminal_id", "paid_at"], name: "index_payments_on_terminal_id_and_paid_at"
    t.index ["user_id", "paid_at"], name: "index_payments_on_user_id_and_paid_at"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "barcode"
    t.bigint "category_id", null: false
    t.decimal "cost", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.decimal "price", precision: 18, scale: 2, default: "0.0", null: false
    t.integer "pricing_mode", default: 0, null: false
    t.string "sku"
    t.decimal "stock", precision: 18, scale: 3, default: "0.0", null: false
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.19", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "category_id"], name: "index_products_on_active_and_category_id"
    t.index ["barcode"], name: "index_products_on_barcode", unique: true, where: "(barcode IS NOT NULL)"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["name"], name: "index_products_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["sku"], name: "index_products_on_sku", unique: true, where: "(sku IS NOT NULL)"
  end

  create_table "sale_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "line_subtotal", precision: 18, scale: 2, null: false
    t.decimal "line_tax", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "line_total", precision: 18, scale: 2, null: false
    t.integer "position", default: 0, null: false
    t.integer "pricing_mode", default: 0, null: false
    t.bigint "product_id", null: false
    t.string "product_name", null: false
    t.string "product_sku"
    t.decimal "quantity", precision: 18, scale: 3, null: false
    t.bigint "sale_id", null: false
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.decimal "unit_price", precision: 18, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "created_at"], name: "index_sale_items_on_product_id_and_created_at"
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id", "position"], name: "index_sale_items_on_sale_id_and_position"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.decimal "cash_amount", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "credit_amount", precision: 18, scale: 2, default: "0.0", null: false
    t.bigint "customer_id"
    t.decimal "discount_total", precision: 18, scale: 2, default: "0.0", null: false
    t.string "number", null: false
    t.integer "payment_method", default: 0, null: false
    t.datetime "sold_at"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "suspended_at"
    t.text "suspended_notes"
    t.decimal "tax_total", precision: 18, scale: 2, default: "0.0", null: false
    t.string "terminal_id", null: false
    t.decimal "total", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.datetime "voided_at"
    t.bigint "voided_by_id"
    t.text "voided_reason"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["number"], name: "index_sales_on_number", unique: true
    t.index ["sold_at"], name: "index_sales_on_sold_at"
    t.index ["status", "sold_at"], name: "index_sales_on_status_and_sold_at"
    t.index ["status"], name: "index_sales_on_status"
    t.index ["suspended_at"], name: "index_sales_on_suspended_at"
    t.index ["terminal_id", "sold_at"], name: "index_sales_on_terminal_id_and_sold_at"
    t.index ["terminal_id", "suspended_at"], name: "index_sales_on_terminal_id_and_suspended_at"
    t.index ["terminal_id"], name: "index_sales_on_terminal_id"
    t.index ["user_id"], name: "index_sales_on_user_id"
    t.index ["voided_by_id"], name: "index_sales_on_voided_by_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "address"
    t.string "business_name", default: "Minimercado", null: false
    t.string "city", default: "Bogotá"
    t.datetime "created_at", null: false
    t.string "legal_name"
    t.string "nit"
    t.integer "paper_width_mm", default: 80, null: false
    t.string "phone"
    t.boolean "print_barcode", default: false, null: false
    t.string "ticket_footer"
    t.string "ticket_header"
    t.datetime "updated_at", null: false
  end

  create_table "stock_reservations", force: :cascade do |t|
    t.string "cart_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 18, scale: 3, null: false
    t.string "terminal_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cart_id"], name: "index_stock_reservations_on_cart_id"
    t.index ["expires_at"], name: "index_stock_reservations_on_expires_at"
    t.index ["product_id", "expires_at"], name: "index_stock_reservations_on_product_id_and_expires_at"
    t.index ["product_id"], name: "index_stock_reservations_on_product_id"
    t.index ["user_id"], name: "index_stock_reservations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 1, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "terminal_assigned"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cash_closings", "users"
  add_foreign_key "credits", "customers"
  add_foreign_key "credits", "sales"
  add_foreign_key "payments", "credits"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "users"
  add_foreign_key "sales", "users", column: "voided_by_id"
  add_foreign_key "stock_reservations", "products"
  add_foreign_key "stock_reservations", "users"
end
