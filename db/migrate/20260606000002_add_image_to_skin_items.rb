class AddImageToSkinItems < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_items, :image, :string
  end
end
