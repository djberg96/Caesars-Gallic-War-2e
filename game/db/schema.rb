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

ActiveRecord::Schema[8.1].define(version: 2026_07_15_000000) do
  create_table "areas", force: :cascade do |t|
    t.string "alternate_tribe"
    t.integer "card_value"
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

  create_table "cards", force: :cascade do |t|
    t.integer "ap", null: false
    t.integer "area_id"
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "kind", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_cards_on_area_id"
    t.index ["key"], name: "index_cards_on_key", unique: true
  end

  create_table "game_session_cards", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "game_session_id", null: false
    t.string "location", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_game_session_cards_on_card_id"
    t.index ["game_session_id", "card_id"], name: "index_game_session_cards_on_game_session_id_and_card_id", unique: true
    t.index ["game_session_id", "location", "position"], name: "idx_on_game_session_id_location_position_a33eb3590f"
    t.index ["game_session_id"], name: "index_game_session_cards_on_game_session_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.string "active_player", default: "roman", null: false
    t.integer "bot_neutral_activations", default: 0, null: false
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.boolean "dice_rolled_this_turn", default: false, null: false
    t.string "mode", default: "hotseat", null: false
    t.string "phase", default: "Card Phase", null: false
    t.boolean "revealed", default: false, null: false
    t.integer "supply", default: 15, null: false
    t.integer "turn_index", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "vp", default: 0, null: false
    t.index ["active_player"], name: "index_game_sessions_on_active_player"
    t.index ["mode"], name: "index_game_sessions_on_mode"
  end

  create_table "game_units", force: :cascade do |t|
    t.integer "area_id"
    t.datetime "created_at", null: false
    t.integer "game_session_id", null: false
    t.string "location", null: false
    t.string "owner", null: false
    t.integer "step", default: 0, null: false
    t.integer "unit_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_game_units_on_area_id"
    t.index ["game_session_id", "unit_type_id"], name: "index_game_units_on_game_session_id_and_unit_type_id", unique: true
    t.index ["game_session_id"], name: "index_game_units_on_game_session_id"
    t.index ["location"], name: "index_game_units_on_location"
    t.index ["unit_type_id"], name: "index_game_units_on_unit_type_id"
  end

  create_table "unit_types", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "fire", null: false
    t.string "home", null: false
    t.string "image_path", null: false
    t.string "initiative", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.json "strengths", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_unit_types_on_key", unique: true
  end

  add_foreign_key "borders", "areas", column: "from_area_id"
  add_foreign_key "borders", "areas", column: "to_area_id"
  add_foreign_key "cards", "areas"
  add_foreign_key "game_session_cards", "cards"
  add_foreign_key "game_session_cards", "game_sessions"
  add_foreign_key "game_units", "areas"
  add_foreign_key "game_units", "game_sessions"
  add_foreign_key "game_units", "unit_types"
end
