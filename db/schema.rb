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

ActiveRecord::Schema.define(version: 20140609222231) do

  create_table "pastes", force: true do |t|
    t.string   "title",      limit: 140
    t.text     "body"
    t.string   "short"
    t.string   "lang_code"
    t.integer  "life_time",  limit: 7,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pastes", ["short"], name: "index_pastes_on_short", unique: true

  create_table "shorts", force: true do |t|
    t.string   "long",       limit: 2024
    t.string   "short"
    t.integer  "life_time",  limit: 7,    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shorts", ["short"], name: "index_shorts_on_short", unique: true

end
