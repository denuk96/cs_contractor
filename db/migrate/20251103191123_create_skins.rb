class CreateSkins < ActiveRecord::Migration[8.1]
  def change
    create_table :skins do |t|
      t.string :name
      t.string :object_id
      t.string :collection_name
      t.string :rarity
      t.boolean :souvenir
      t.boolean :stattrak
      t.string :category
      t.float :min_float
      t.float :max_float
      t.text :wears
      t.text :crates
      t.text :weapon

      t.timestamps
    end
    add_index :skins, :object_id, unique: true
    add_index :skins, :name, unique: true

    add_reference :skin_items, :skin, foreign_key: true
  end
end
