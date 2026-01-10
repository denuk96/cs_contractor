class AddMetaToSkinItemHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_item_histories, :metadata, :text
  end
end
