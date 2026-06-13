# frozen_string_literal: true

module SkinItems
  module Signals
    # "Buy Order Increase": demand (buy order volume) has climbed
    # meaningfully since the earliest recorded snapshot, which can signal
    # accumulation before a price move.
    class BuyOrderIncreaseQuery < BaseQuery
      INCREASE_RATIO_THRESHOLD = 0.20
      MIN_PREV_BUY_ORDER_VOLUME = 5

      def self.signal_type
        "buy_order_increase"
      end

      def self.headline(item)
        pct = increase_ratio(item) * 100

        "Buy orders rose from #{item.prev_buyordervolume} to #{item.current_buyordervolume} " \
          "(+#{pct.round(1)}%)"
      end

      def self.details(item)
        {
          buy_order_volume: item.current_buyordervolume,
          prev_buy_order_volume: item.prev_buyordervolume,
          increase_pct: (increase_ratio(item) * 100).round(1),
          latest_price: item.current_price
        }
      end

      def self.increase_ratio(item)
        (item.current_buyordervolume.to_f - item.prev_buyordervolume.to_f) / item.prev_buyordervolume.to_f
      end
      private_class_method :increase_ratio

      private

      def signal_conditions
        <<~SQL.squish
          h1.id IS NOT NULL AND h2.id IS NOT NULL
          AND h2.buyordervolume >= #{MIN_PREV_BUY_ORDER_VOLUME}
          AND h1.buyordervolume > h2.buyordervolume
          AND (CAST(h1.buyordervolume - h2.buyordervolume AS REAL) / h2.buyordervolume) >= #{INCREASE_RATIO_THRESHOLD}
        SQL
      end
    end
  end
end
