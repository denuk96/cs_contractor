# frozen_string_literal: true

module Feed
  # Runs each "signal" query and upserts a `FeedItem` per matching
  # `SkinItem`, so the feed page can show why an item is currently trending.
  #
  # Queries are ranked by priority: an item matching more than one signal in
  # the same run only gets a single feed entry, for its highest-priority
  # signal, so the same item never appears twice for different reasons.
  #
  # Re-running is idempotent: an item that keeps matching just has its
  # signal/headline/details refreshed in place.
  class GenerateEntries
    SIGNAL_QUERIES = [
      SkinItems::Signals::TopSignalsQuery,
      SkinItems::Signals::SupplyDryUpQuery,
      SkinItems::Signals::BuyOrderIncreaseQuery
    ].freeze

    def call
      seen_skin_item_ids = Set.new

      SIGNAL_QUERIES.each do |query_class|
        query_class.new.call.each do |item|
          next if item.current_date.blank?
          next unless seen_skin_item_ids.add?(item.id)

          upsert_feed_item(query_class, item)
        end
      end
    end

    private

    def upsert_feed_item(query_class, item)
      FeedItem
        .find_or_initialize_by(skin_item_id: item.id)
        .update!(
          signal_type: query_class.signal_type,
          occurred_on: item.current_date,
          headline: query_class.headline(item),
          details: query_class.details(item)
        )
    end
  end
end
