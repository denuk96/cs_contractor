# frozen_string_literal: true

module SkinItems
  module Signals
    # "Pump Alert": buy orders dwarf the sell listings (a buy wall), turnover
    # is high, supply is shrinking, and the buy order price is close to the
    # ask. Mirrors the `top_signals` sort on the trending page.
    class TopSignalsQuery < BaseQuery
      BUY_WALL_RATIO_THRESHOLD = 50
      TURNOVER_RATIO_THRESHOLD = 0.15
      BUY_ORDER_PRICE_RATIO_THRESHOLD = 0.85
      COMPARISON_WINDOW_DAYS = 10

      def self.signal_type
        "top_signals"
      end

      def self.headline(item)
        ratio = buy_wall_ratio(item)
        turnover = turnover_ratio(item)

        "Pump alert: buy wall at #{ratio ? "#{ratio.round(1)}x" : '?'} offer volume" \
          " with #{turnover ? "#{(turnover * 100).round(1)}%" : '?'} daily turnover"
      end

      def self.details(item)
        {
          buy_wall_ratio: buy_wall_ratio(item)&.round(2),
          turnover_pct: turnover_ratio(item) ? (turnover_ratio(item) * 100).round(1) : nil,
          buy_order_price: item.current_buyorderprice,
          latest_price: item.current_price,
          offer_volume: item.current_offervolume,
          prev_offer_volume: item.prev_offervolume
        }
      end

      def self.buy_wall_ratio(item)
        return nil if item.current_offervolume.to_i.zero?

        item.current_buyordervolume.to_f / item.current_offervolume
      end

      def self.turnover_ratio(item)
        return nil if item.current_offervolume.to_i.zero?

        item.current_soldtoday.to_f / item.current_offervolume
      end
      private_class_method :buy_wall_ratio, :turnover_ratio

      private

      def h2_date_subquery
        "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id " \
          "AND date <= date(#{h1_date_subquery}, '-#{COMPARISON_WINDOW_DAYS} days'))"
      end

      def signal_conditions
        <<~SQL.squish
          h1.id IS NOT NULL AND h2.id IS NOT NULL
          AND (CAST(h1.buyordervolume AS REAL) / NULLIF(h1.offervolume, 0)) > #{BUY_WALL_RATIO_THRESHOLD}
          AND (CAST(h1.soldtoday AS REAL) / NULLIF(h1.offervolume, 0)) > #{TURNOVER_RATIO_THRESHOLD}
          AND h1.offervolume < h2.offervolume
          AND h1.buyorderprice > (#{BUY_ORDER_PRICE_RATIO_THRESHOLD} * h1.pricelatest)
        SQL
      end
    end
  end
end
