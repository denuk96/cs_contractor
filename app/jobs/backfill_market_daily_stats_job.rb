class BackfillMarketDailyStatsJob < ApplicationJob
  include NotifiesOnFailure

  # First date the tracker has usable price history for.
  HISTORY_START = Date.new(2025, 12, 25)

  queue_as :default

  # Fans the rebuild out into one `RecalculateMarketDayJob` per day, so a
  # months-long backfill never sits in a single long-running job.
  #
  # Dates are passed as ISO strings so the enqueued arguments stay readable in
  # the Mission Control UI and survive any serializer changes.
  def perform(from = HISTORY_START.to_s, to = nil)
    earliest = SkinItemHistory.minimum(:date)&.to_date
    latest = SkinItemHistory.maximum(:date)&.to_date
    return Rails.logger.info("[BackfillMarketDailyStats] no history to roll up") if earliest.nil?

    # Clamp to the recorded history so the fan-out never covers empty days.
    from = [from.to_date, earliest].max
    to = [to.presence&.to_date || latest, latest].min
    return Rails.logger.info("[BackfillMarketDailyStats] nothing to rebuild for #{from}..#{to}") if from > to

    dates = (from..to).to_a
    dates.each { |date| RecalculateMarketDayJob.perform_later(date.to_s) }

    Rails.logger.info("[BackfillMarketDailyStats] enqueued #{dates.size} day job(s) for #{from}..#{to}")
  end
end
