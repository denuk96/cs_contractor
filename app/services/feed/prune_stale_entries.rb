# frozen_string_literal: true

module Feed
  # Deletes `FeedItem` records whose signal hasn't fired again recently, so
  # the feed only shows items that are still currently relevant.
  class PruneStaleEntries
    RETENTION_DAYS = 7

    def call
      FeedItem.where(occurred_on: ...cutoff_date).delete_all
    end

    private

    def cutoff_date
      Date.current - RETENTION_DAYS.days
    end
  end
end
