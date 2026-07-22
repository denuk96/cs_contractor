class RecalculateMarketDayJob < ApplicationJob
  include NotifiesOnFailure

  queue_as :default

  # Rebuilds the rollup for a single date. Backfills fan out one of these per
  # day so each unit stays small and retries on its own.
  def perform(date)
    date = date.to_date
    result = Market::RecalculateDailyStats.new(from: date, to: date).call

    Rails.logger.info("[RecalculateMarketDay] #{date}: #{result.rows_written} row(s) rebuilt")
  end
end
