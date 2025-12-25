class CreateSkinItemHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :skin_item_histories do |t|
      t.belongs_to :skin_item, null: false, foreign_key: true
      t.float :pricelatest
      t.float :pricemedian
      t.float :pricemedian24h
      t.float :pricemedian7d
      t.float :pricemedian30d
      t.float :pricemedian90d
      t.integer :sold24h
      t.integer :sold7d
      t.integer :sold30d
      t.integer :sold90d
      t.integer :soldtotal
      t.integer :soldtoday

      t.integer :buyordervolume
      t.float :buyorderprice
      t.float :buyordermedian
      t.float :buyorderavg
      t.integer :offervolume

      t.date :date, null: false


      t.timestamps
    end
    add_index :skin_item_histories, [:skin_item_id, :date], unique: true
  end
end
