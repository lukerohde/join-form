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

ActiveRecord::Schema.define(version: 20160404023428) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "join_forms", force: :cascade do |t|
    t.string   "short_name"
    t.text     "description"
    t.text     "css"
    t.decimal  "base_rate_establishment", precision: 6, scale: 2
    t.decimal  "base_rate_weekly",        precision: 6, scale: 2
    t.decimal  "base_rate_fortnightly",   precision: 6, scale: 2
    t.decimal  "base_rate_monthly",       precision: 6, scale: 2
    t.decimal  "base_rate_quarterly",     precision: 6, scale: 2
    t.decimal  "base_rate_half_yearly",   precision: 6, scale: 2
    t.decimal  "base_rate_yearly",        precision: 6, scale: 2
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "union_id"
    t.integer  "person_id"
  end

  add_index "join_forms", ["person_id"], name: "index_join_forms_on_person_id", using: :btree
  add_index "join_forms", ["union_id"], name: "index_join_forms_on_union_id", using: :btree

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
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",      default: 0
    t.integer  "union_id"
    t.string   "stripe_token"
  end

  add_index "people", ["email"], name: "index_people_on_email", unique: true, using: :btree
  add_index "people", ["invitation_token"], name: "index_people_on_invitation_token", unique: true, using: :btree
  add_index "people", ["invitations_count"], name: "index_people_on_invitations_count", using: :btree
  add_index "people", ["invited_by_id"], name: "index_people_on_invited_by_id", using: :btree
  add_index "people", ["reset_password_token"], name: "index_people_on_reset_password_token", unique: true, using: :btree
  add_index "people", ["union_id"], name: "index_people_on_union_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "join_form_id"
    t.string   "frequency"
    t.string   "pay_method"
    t.string   "account_name"
    t.string   "account_number"
    t.string   "ccv"
    t.string   "bsb"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "expiry_month"
    t.integer  "expiry_year"
    t.string   "stripe_token"
    t.string   "plan"
    t.string   "card_number"
    t.string   "token"
    t.string   "callback_url"
  end

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
  end

  add_foreign_key "join_forms", "people"
  add_foreign_key "join_forms", "supergroups", column: "union_id"
  add_foreign_key "people", "supergroups", column: "union_id"
  add_foreign_key "subscriptions", "join_forms"
  add_foreign_key "subscriptions", "people"
end
