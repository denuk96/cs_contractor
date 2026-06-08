class CreateSkinItemHistoryPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :skin_item_history_prices do |t|
      # FK lookups are served by the leading column of the unique index below,
      # so we skip the default single-column index to avoid a redundant one.
      t.references :skin_item_history, null: false, foreign_key: true, index: false
      t.string :source, null: false
      t.float :price
      t.integer :quantity
      t.string :kind, null: false, default: "offer"
      t.datetime :source_updated_at

      t.timestamps
    end

    # One quote per market per snapshot; also serves FK lookups and upserts.
    add_index :skin_item_history_prices,
              %i[skin_item_history_id source],
              unique: true,
              name: "idx_sihp_on_history_and_source"
    # Cross-market filters scan by market (e.g. WHERE source = 'buff').
    add_index :skin_item_history_prices, :source
  end
end