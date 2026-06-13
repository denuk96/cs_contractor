class AddInGameStoreToSkinItems < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_items, :in_game_store, :boolean, default: false, null: false
  end
end
