class CreateMarketDailyStats < ActiveRecord::Migration[8.1]
  def change
    create_table :market_daily_stats do |t|
      t.date :date, null: false

      # The segment this row covers. Rows are keyed by the three skin_item flags
      # the overview page filters on, so any filter combination is served by
      # summing the matching segments — no per-filter rollup needed.
      t.boolean :stattrak, null: false, default: false
      t.boolean :souvenir, null: false, default: false
      t.boolean :in_game_store, null: false, default: false

      # Additive aggregates of skin_item_histories for that date + segment.
      t.integer :items_tracked, null: false, default: 0
      t.integer :sold_volume, null: false, default: 0
      t.integer :offer_volume, null: false, default: 0
      t.integer :buy_order_volume, null: false, default: 0
      t.float :traded_value, null: false, default: 0.0
      t.float :listed_value, null: false, default: 0.0

      # Average price is not additive, so store its components instead and let
      # the reader divide after summing across segments.
      t.float :price_sum, null: false, default: 0.0
      t.integer :priced_items, null: false, default: 0

      t.timestamps
    end

    add_index :market_daily_stats,
              %i[date stattrak souvenir in_game_store],
              unique: true,
              name: "index_market_daily_stats_on_date_and_segment"
  end
end
