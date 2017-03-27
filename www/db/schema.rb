# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170323231506) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bootsy_image_galleries", force: :cascade do |t|
    t.integer  "bootsy_resource_id"
    t.string   "bootsy_resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bootsy_images", force: :cascade do |t|
    t.string   "image_file"
    t.integer  "image_gallery_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string   "subject"
    t.text     "body_html"
    t.text     "css"
    t.text     "body_plain"
    t.string   "attachment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "short_name"
    t.text     "pdf_html"
  end

  create_table "follows", force: :cascade do |t|
    t.string   "follower_type"
    t.integer  "follower_id"
    t.string   "followable_type"
    t.integer  "followable_id"
    t.datetime "created_at"
  end

  add_index "follows", ["followable_id", "followable_type"], name: "fk_followables", using: :btree
  add_index "follows", ["follower_id", "follower_type"], name: "fk_follows", using: :btree

  create_table "join_form_translations", force: :cascade do |t|
    t.integer  "join_form_id",   null: false
    t.string   "locale",         null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.text     "description"
    t.text     "page_title"
    t.text     "schema"
    t.text     "header"
    t.text     "footer"
    t.text     "css"
    t.text     "wysiwyg_header"
    t.text     "wysiwyg_footer"
  end

  add_index "join_form_translations", ["join_form_id"], name: "index_join_form_translations_on_join_form_id", using: :btree
  add_index "join_form_translations", ["locale"], name: "index_join_form_translations_on_locale", using: :btree

  create_table "join_forms", force: :cascade do |t|
    t.string   "short_name"
    t.text     "description"
    t.text     "css"
    t.decimal  "base_rate_establishment",   precision: 6, scale: 2
    t.decimal  "base_rate_weekly",          precision: 6, scale: 2
    t.decimal  "base_rate_fortnightly",     precision: 6, scale: 2
    t.decimal  "base_rate_monthly",         precision: 6, scale: 2
    t.decimal  "base_rate_quarterly",       precision: 6, scale: 2
    t.decimal  "base_rate_half_yearly",     precision: 6, scale: 2
    t.decimal  "base_rate_yearly",          precision: 6, scale: 2
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "union_id"
    t.integer  "admin_id"
    t.string   "base_rate_id"
    t.text     "header"
    t.string   "page_title"
    t.json     "plans"
    t.text     "schema",                                            default: "{}",  null: false
    t.boolean  "signature_required",                                default: false
    t.integer  "welcome_email_template_id"
    t.boolean  "advanced_designer"
    t.text     "footer"
    t.text     "wysiwyg_header"
    t.text     "wysiwyg_footer"
    t.boolean  "credit_card_on"
    t.boolean  "direct_debit_on"
    t.boolean  "payroll_deduction_on"
    t.boolean  "direct_debit_release_on"
    t.integer  "admin_email_template_id"
    t.string   "group_id"
    t.string   "tags"
    t.integer  "organiser_id"
    t.boolean  "deferral_on",                                       default: false, null: false
    t.boolean  "address_on",                                        default: true,  null: false
  end

  add_index "join_forms", ["admin_id"], name: "index_join_forms_on_admin_id", using: :btree
  add_index "join_forms", ["union_id"], name: "index_join_forms_on_union_id", using: :btree
  add_index "join_forms", ["welcome_email_template_id"], name: "index_join_forms_on_welcome_email_template_id", using: :btree

  create_table "payments", force: :cascade do |t|
    t.date     "date"
    t.decimal  "amount",          precision: 8, scale: 2
    t.string   "external_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "person_id"
    t.integer  "subscription_id"
  end

  add_index "payments", ["person_id"], name: "index_payments_on_person_id", using: :btree
  add_index "payments", ["subscription_id"], name: "index_payments_on_subscription_id", using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.string   "attachment"
    t.string   "address1"
    t.string   "address2"
    t.string   "suburb"
    t.string   "state"
    t.string   "postcode"
    t.string   "gender"
    t.string   "mobile"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.string   "invited_by_type"
    t.integer  "invited_by_id"
    t.integer  "invitations_count",      default: 0
    t.integer  "union_id"
    t.string   "stripe_token"
    t.date     "dob"
    t.string   "external_id"
  end

  add_index "people", ["email"], name: "index_people_on_email", unique: true, using: :btree
  add_index "people", ["invitation_token"], name: "index_people_on_invitation_token", unique: true, using: :btree
  add_index "people", ["invitations_count"], name: "index_people_on_invitations_count", using: :btree
  add_index "people", ["invited_by_id"], name: "index_people_on_invited_by_id", using: :btree
  add_index "people", ["reset_password_token"], name: "index_people_on_reset_password_token", unique: true, using: :btree
  add_index "people", ["union_id"], name: "index_people_on_union_id", using: :btree

  create_table "record_batches", force: :cascade do |t|
    t.string   "name"
    t.integer  "email_template_id"
    t.integer  "sms_template_id"
    t.integer  "join_form_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "sender_id"
    t.string   "sender_sms_address"
    t.string   "sender_email_address"
  end

  create_table "records", force: :cascade do |t|
    t.string   "type"
    t.string   "subject"
    t.text     "body_plain"
    t.text     "body_html"
    t.string   "delivery_status"
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.string   "recipient_address"
    t.string   "sender_address"
    t.integer  "template_id"
    t.integer  "parent_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "join_form_id"
    t.string   "message_id"
    t.integer  "record_batch_id"
  end

  create_table "sms_templates", force: :cascade do |t|
    t.string   "short_name"
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "join_form_id"
    t.string   "frequency"
    t.string   "pay_method"
    t.string   "account_name"
    t.string   "account_number"
    t.string   "ccv"
    t.string   "bsb"
    t.datetime "created_at",                                                           null: false
    t.datetime "updated_at",                                                           null: false
    t.integer  "expiry_month"
    t.integer  "expiry_year"
    t.string   "stripe_token"
    t.string   "plan"
    t.string   "card_number"
    t.string   "token"
    t.string   "callback_url"
    t.string   "status"
    t.jsonb    "data",                                                 default: {},    null: false
    t.string   "signature_vector"
    t.string   "signature_image"
    t.date     "next_payment_date"
    t.date     "financial_date"
    t.string   "partial_account_number"
    t.string   "partial_card_number"
    t.string   "partial_bsb"
    t.boolean  "end_point_put_required",                               default: false
    t.decimal  "up_front_payment",             precision: 8, scale: 2
    t.date     "first_recurrent_payment_date"
    t.date     "signature_date"
    t.string   "country_code"
    t.string   "source"
    t.boolean  "renewal",                                              default: false, null: false
    t.boolean  "pending",                                              default: false, null: false
    t.datetime "completed_at"
    t.date     "deduction_date"
  end

  add_index "subscriptions", ["data"], name: "index_subscriptions_on_data", using: :gin
  add_index "subscriptions", ["join_form_id"], name: "index_subscriptions_on_join_form_id", using: :btree
  add_index "subscriptions", ["person_id"], name: "index_subscriptions_on_person_id", using: :btree

  create_table "supergroups", force: :cascade do |t|
    t.string   "name"
    t.string   "type"
    t.string   "www"
    t.string   "logo"
    t.string   "short_name"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "stripe_access_token"
    t.string   "stripe_refresh_token"
    t.string   "stripe_publishable_key"
    t.string   "stripe_user_id"
    t.string   "phone"
    t.text     "key_pair"
  end

  add_foreign_key "join_forms", "email_templates", column: "welcome_email_template_id"
  add_foreign_key "join_forms", "people", column: "admin_id"
  add_foreign_key "join_forms", "supergroups", column: "union_id"
  add_foreign_key "payments", "people"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "people", "supergroups", column: "union_id"
  add_foreign_key "subscriptions", "join_forms"
  add_foreign_key "subscriptions", "people"
end
