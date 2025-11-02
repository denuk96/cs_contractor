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

ActiveRecord::Schema[8.1].define(version: 2025_11_02_140413) do
  create_table "skin_items", force: :cascade do |t|
    t.string "category"
    t.string "collection_name"
    t.datetime "created_at", null: false
    t.float "latest_steam_price"
    t.float "max_float"
    t.float "min_float"
    t.string "name"
    t.string "object_id"
    t.integer "rarity"
    t.boolean "souvenir"
    t.boolean "stattrak"
    t.datetime "updated_at", null: false
    t.integer "wear"
  end
end
