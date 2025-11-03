class AddUniqIndexToNameToSkinItem < ActiveRecord::Migration[8.1]
  def change
    add_index :skin_items, :name, unique: true
    remove_column :skin_items, :collection_name
  end
end
