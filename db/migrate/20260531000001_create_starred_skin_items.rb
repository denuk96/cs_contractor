class CreateStarredSkinItems < ActiveRecord::Migration[8.0]
  def change
    create_table :starred_skin_items do |t|
      t.references :skin_item, null: false, foreign_key: true
      # No auth yet. user_id is nullable for now so we can attach stars to a
      # User model later without another migration. Uniqueness is enforced per
      # (user, item) once users exist; today all stars share a NULL user.
      t.bigint :user_id

      t.timestamps
    end

    add_index :starred_skin_items, [:user_id, :skin_item_id], unique: true
  end
end
