class RecalculateMarketStatsJob < ApplicationJob
  include NotifiesOnFailure

  # Today plus the two previous days: price imports land under `Time.zone.today`,
  # and a late or retried import can still change a day after midnight.
  RECALC_DAYS = 3

  queue_as :default

  def perform(days = RECALC_DAYS)
    from = Date.current - (days - 1)
    result = Market::RecalculateDailyStats.new(from: from, to: Date.current).call

    Rails.logger.info(
      "[RecalculateMarketStats] #{result.rows_written} row(s) rebuilt for #{result.from}..#{result.to}"
    )
  end
end
