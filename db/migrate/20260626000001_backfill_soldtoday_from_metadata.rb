class BackfillSoldtodayFromMetadata < ActiveRecord::Migration[8.0]
  def up
    SkinItemHistory.where.not(metadata: nil).find_each do |history|
      meta = history.metadata
      value = meta["sold24h"] || meta["soldtoday"]
      next if value.nil?
      history.update_columns(soldtoday: value.to_i)
    end
  end

  def down
    # intentionally irreversible — we're only filling nulls
  end
end
