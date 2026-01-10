class AddAllMarketsQuantityToSkinItemHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_item_histories, :all_markets_quantity, :integer
    add_column :skin_item_histories, :all_markets_weighted_median_price, :float
  end
end
