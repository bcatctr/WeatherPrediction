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

ActiveRecord::Schema.define(version: 20150524054612) do

  create_table "location_predictions", force: :cascade do |t|
    t.integer  "period"
    t.date     "time"
    t.float    "lon"
    t.float    "lat"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "location_id"
  end

  add_index "location_predictions", ["location_id"], name: "index_location_predictions_on_location_id"

  create_table "locations", force: :cascade do |t|
    t.string   "location_id"
    t.float    "lat"
    t.float    "long"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "postCode_id"
  end

  add_index "locations", ["postCode_id"], name: "index_locations_on_postCode_id"

  create_table "parsers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "post_codes", force: :cascade do |t|
    t.integer  "postCode_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "postcode_predictions", force: :cascade do |t|
    t.integer  "period"
    t.date     "time"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "postCode_id"
  end

  add_index "postcode_predictions", ["postCode_id"], name: "index_postcode_predictions_on_postCode_id"

  create_table "weathers", force: :cascade do |t|
    t.string   "date"
    t.float    "temperature"
    t.float    "windSpeed"
    t.float    "windDirection"
    t.float    "rainFall"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "location_id"
    t.time     "time"
  end

  add_index "weathers", ["location_id"], name: "index_weathers_on_location_id"

end
