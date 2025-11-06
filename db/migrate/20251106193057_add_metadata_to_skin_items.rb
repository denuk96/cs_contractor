class AddMetadataToSkinItems < ActiveRecord::Migration[8.1]
  def change
    add_column :skin_items, :metadata, :text
  end
end
