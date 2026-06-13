# frozen_string_literal: true

module SkinItems
  module Signals
    # Last `DAYS` days of price-history snapshots for a set of skin items,
    # grouped by skin_item_id. Powers the feed's "why" mini charts.
    class RecentHistoryQuery
      DAYS = 14

      def initialize(skin_item_ids)
        @skin_item_ids = skin_item_ids
      end

      def call
        SkinItemHistory
          .where(skin_item_id: skin_item_ids)
          .where(date: (Date.current - (DAYS - 1))..)
          .order(:date)
          .group_by(&:skin_item_id)
      end

      private

      attr_reader :skin_item_ids
    end
  end
end
