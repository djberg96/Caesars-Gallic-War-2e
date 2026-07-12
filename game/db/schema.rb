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

ActiveRecord::Schema[8.1].define(version: 2026_07_11_000003) do
  create_table "areas", force: :cascade do |t|
    t.string "alternate_tribe"
    t.datetime "created_at", null: false
    t.integer "fort_level"
    t.string "fort_name"
    t.string "key", null: false
    t.string "name", null: false
    t.boolean "port", default: false, null: false
    t.string "region"
    t.boolean "sea", default: false, null: false
    t.text "special"
    t.json "tribes", default: [], null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.index ["key"], name: "index_areas_on_key", unique: true
  end

  create_table "borders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "from_area_id", null: false
    t.string "kind", null: false
    t.integer "to_area_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_area_id", "to_area_id"], name: "index_borders_on_from_area_id_and_to_area_id", unique: true
    t.index ["from_area_id"], name: "index_borders_on_from_area_id"
    t.index ["to_area_id"], name: "index_borders_on_to_area_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "borders", "areas", column: "from_area_id"
  add_foreign_key "borders", "areas", column: "to_area_id"
end
