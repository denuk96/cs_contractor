# Data migration: `all_markets_quantity` used to sum the steamwebapi `prices`
# array as-is, but that array holds one entry per intraday snapshot per market,
# so a single source (Skinport routinely) got counted dozens of times and supply
# came out heavily inflated. Reimport the column from the stored metadata using
# the same dedup-by-source rule the importer now applies.
class BackfillAllMarketsQuantityFromMetadata < ActiveRecord::Migration[8.1]
  BATCH_SIZE = 500

  # SQLite has a single writer, so wrapping the whole sweep in one transaction
  # would lock out the importer and web writes for its full runtime. Commit row
  # by row instead — the sweep is idempotent, so an interrupted run can simply be
  # re-run and will skip whatever it already fixed.
  disable_ddl_transaction!

  def up
    # Raw SQL predicate: `metadata` is a serialized Hash column, so comparing it
    # to a String through the query builder raises SerializationTypeMismatch.
    scope = SkinItemHistory.where("metadata IS NOT NULL AND metadata != ''")
                           .select(:id, :all_markets_quantity, :metadata)
    updated = 0

    scope.find_each(batch_size: BATCH_SIZE) do |history|
      metadata = history.metadata
      next unless metadata.is_a?(Hash)

      quantity = Import::MarketPrices.total_market_quantity(metadata)
      next if quantity == history.all_markets_quantity

      history.update_columns(all_markets_quantity: quantity)
      updated += 1
    end

    say "Reimported all_markets_quantity for #{updated} histories"
  end

  def down
    # intentionally irreversible — the previous values were inflated by
    # duplicate market snapshots and carry no information worth restoring
  end
end
