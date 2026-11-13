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

ActiveRecord::Schema[7.2].define(version: 2026_11_13_090000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lawsuit_id", null: false
    t.integer "user_id", null: false
    t.index ["lawsuit_id"], name: "index_comments_on_lawsuit_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "courts", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_courts_on_lower_name", unique: true
  end

  create_table "lawsuit_representatives", force: :cascade do |t|
    t.integer "lawsuit_id", null: false
    t.integer "user_id", null: false
    t.boolean "is_primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lawsuit_id", "user_id"], name: "index_lawsuit_representatives_on_lawsuit_id_and_user_id", unique: true
    t.index ["lawsuit_id"], name: "index_lawsuit_representatives_on_lawsuit_id"
    t.index ["lawsuit_id"], name: "index_lawsuit_representatives_one_primary", unique: true, where: "is_primary"
    t.index ["user_id"], name: "index_lawsuit_representatives_on_user_id"
  end

  create_table "lawsuits", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "status"
    t.text "description"
    t.string "context_type"
    t.string "plaintiff"
    t.string "lawsuit_claim"
    t.string "lawsuit_number"
    t.string "court"
    t.decimal "lawsuit_amount_claim"
    t.decimal "provision"
    t.string "lawsuit_risk"
    t.string "lawsuit_state"
    t.string "civil_lawsuit"
    t.string "lawsuit_phase_procedure"
    t.string "institution"
    t.string "lawsuit_development_procedure"
    t.datetime "discarded_at"
    t.text "deletion_reason"
    t.integer "deleted_by_user_id"
    t.datetime "deleted_at"
    t.string "final_status"
    t.index ["discarded_at"], name: "index_lawsuits_on_discarded_at"
    t.index ["title", "lawsuit_number"], name: "index_lawsuits_on_title_and_number_active", unique: true, where: "discarded_at IS NULL"
  end

  create_table "pdf_file_deletions", force: :cascade do |t|
    t.integer "lawsuit_id", null: false
    t.integer "attachment_id", null: false
    t.integer "deleted_by_user_id", null: false
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachment_id"], name: "index_pdf_file_deletions_on_attachment_id", unique: true
    t.index ["deleted_by_user_id"], name: "index_pdf_file_deletions_on_deleted_by_user_id"
    t.index ["lawsuit_id"], name: "index_pdf_file_deletions_on_lawsuit_id"
  end

  create_table "provisions", force: :cascade do |t|
    t.integer "lawsuit_id", null: false
    t.decimal "provision_value"
    t.integer "provision_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lawsuit_id"], name: "index_provisions_on_lawsuit_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "surname"
    t.integer "kt_id"
    t.integer "role"
    t.boolean "active", default: true, null: false
    t.string "category_scopes", default: [], null: false, array: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["kt_id"], name: "index_users_on_kt_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object", limit: 1073741823
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "lawsuits"
  add_foreign_key "comments", "users"
  add_foreign_key "lawsuit_representatives", "lawsuits"
  add_foreign_key "lawsuit_representatives", "users"
  add_foreign_key "pdf_file_deletions", "active_storage_attachments", column: "attachment_id"
  add_foreign_key "pdf_file_deletions", "lawsuits"
  add_foreign_key "pdf_file_deletions", "users", column: "deleted_by_user_id"
  add_foreign_key "provisions", "lawsuits"
end
