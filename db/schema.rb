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

ActiveRecord::Schema[8.1].define(version: 2025_12_25_170718) do
  create_table "skin_item_histories", force: :cascade do |t|
    t.float "buyorderavg"
    t.float "buyordermedian"
    t.float "buyorderprice"
    t.integer "buyordervolume"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "offervolume"
    t.float "pricelatest"
    t.float "pricemedian"
    t.float "pricemedian24h"
    t.float "pricemedian30d"
    t.float "pricemedian7d"
    t.float "pricemedian90d"
    t.integer "skin_item_id", null: false
    t.integer "sold24h"
    t.integer "sold30d"
    t.integer "sold7d"
    t.integer "sold90d"
    t.integer "soldtoday"
    t.integer "soldtotal"
    t.datetime "updated_at", null: false
    t.index ["skin_item_id", "date"], name: "index_skin_item_histories_on_skin_item_id_and_date", unique: true
    t.index ["skin_item_id"], name: "index_skin_item_histories_on_skin_item_id"
  end

  create_table "skin_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_steam_price_updated_at"
    t.float "latest_steam_order_price"
    t.float "latest_steam_price"
    t.text "metadata"
    t.string "name"
    t.integer "rarity"
    t.integer "skin_id"
    t.boolean "souvenir"
    t.boolean "stattrak"
    t.datetime "updated_at", null: false
    t.integer "wear"
    t.index ["name"], name: "index_skin_items_on_name", unique: true
    t.index ["skin_id"], name: "index_skin_items_on_skin_id"
  end

  create_table "skins", force: :cascade do |t|
    t.string "category"
    t.string "collection_name"
    t.text "crates"
    t.datetime "created_at", null: false
    t.float "max_float"
    t.float "min_float"
    t.string "name"
    t.string "object_id"
    t.string "rarity"
    t.boolean "souvenir"
    t.boolean "stattrak"
    t.datetime "updated_at", null: false
    t.text "weapon"
    t.text "wears"
    t.index ["name"], name: "index_skins_on_name", unique: true
    t.index ["object_id"], name: "index_skins_on_object_id", unique: true
  end

  add_foreign_key "skin_item_histories", "skin_items"
  add_foreign_key "skin_items", "skins"
end
