class ChangeFeedItemsUniqueIndexToSkinItem < ActiveRecord::Migration[8.1]
  def change
    remove_index :feed_items, name: "idx_feed_items_on_item_signal_date"

    # One feed entry per skin item, regardless of signal/date; refreshed in
    # place when a new (or the same) signal fires again.
    add_index :feed_items, :skin_item_id, unique: true
  end
end
