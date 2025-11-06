class AddLatestOrderPriceToSkinItems < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_items, :latest_steam_order_price, :float
  end
end
