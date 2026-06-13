class CreateFeedItems < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_items do |t|
      t.references :skin_item, null: false, foreign_key: true, index: false
      t.string :signal_type, null: false
      t.date :occurred_on, null: false
      t.string :headline, null: false
      t.text :details

      t.timestamps
    end

    # One feed entry per item/signal/day; also serves FK and feed lookups.
    add_index :feed_items, %i[skin_item_id signal_type occurred_on],
              unique: true,
              name: "idx_feed_items_on_item_signal_date"
    add_index :feed_items, %i[occurred_on signal_type]
  end
end
