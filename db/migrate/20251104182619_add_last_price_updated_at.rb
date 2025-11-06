class AddLastPriceUpdatedAt < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_items, :last_steam_price_updated_at, :datetime
  end
end
