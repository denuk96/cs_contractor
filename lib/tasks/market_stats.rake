namespace :market_stats do
  desc "Enqueue a market_daily_stats rebuild (FROM=2025-12-25 TO=today)"
  task backfill: :environment do
    from = ENV["FROM"].presence || BackfillMarketDailyStatsJob::HISTORY_START.to_s

    BackfillMarketDailyStatsJob.perform_later(from, ENV["TO"].presence)
    puts "Enqueued BackfillMarketDailyStatsJob from #{from}"
  end

  desc "Rebuild the last N days of market_daily_stats (DAYS=3)"
  task recent: :environment do
    days = (ENV["DAYS"] || RecalculateMarketStatsJob::RECALC_DAYS).to_i
    RecalculateMarketStatsJob.perform_now(days)
  end
end
