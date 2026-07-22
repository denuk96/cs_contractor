# Data migration: fills `market_daily_stats` for the whole tracked period so the
# overview page has something to read once this deploys.
#
# The rebuild is handed to `BackfillMarketDailyStatsJob` rather than run inline —
# a multi-month rollup should not hold up `db:prepare` on boot. The job is
# idempotent, so re-running it (or `rake market_stats:backfill`) is always safe.
class BackfillMarketDailyStats < ActiveRecord::Migration[8.1]
  def up
    from = BackfillMarketDailyStatsJob::HISTORY_START

    BackfillMarketDailyStatsJob.perform_later(from.to_s)
    say "Enqueued BackfillMarketDailyStatsJob from #{from}"
  end

  def down
    MarketDailyStat.where(date: BackfillMarketDailyStatsJob::HISTORY_START..).delete_all
  end
end
