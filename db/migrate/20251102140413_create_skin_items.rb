class CreateSkinItems < ActiveRecord::Migration[8.1]
  def change
    create_table :skin_items do |t|
      t.string :name
      t.integer :rarity
      t.integer :wear
      t.string :collection_name
      t.boolean :souvenir
      t.boolean :stattrak
      t.float :latest_steam_price

      t.timestamps
    end
  end
end
