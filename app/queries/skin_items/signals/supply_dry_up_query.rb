# frozen_string_literal: true

module SkinItems
  module Signals
    # "Supply Dry Up": today's sales are eating through the available offer
    # volume fast enough to enter the "Squeeze Zone" (>=20% turnover), the
    # same threshold used on the item page's turnover dashboard.
    class SupplyDryUpQuery < BaseQuery
      TURNOVER_RATIO_THRESHOLD = 0.20

      def self.signal_type
        "supply_dry_up"
      end

      def self.headline(item)
        turnover = turnover_ratio(item)

        "Supply drying up: #{(turnover * 100).round(1)}% turnover " \
          "(#{item.current_soldtoday} sold of #{item.current_offervolume} listed today)"
      end

      def self.details(item)
        {
          turnover_pct: (turnover_ratio(item) * 100).round(1),
          sold_today: item.current_soldtoday,
          offer_volume: item.current_offervolume,
          latest_price: item.current_price
        }
      end

      def self.turnover_ratio(item)
        item.current_soldtoday.to_f / item.current_offervolume
      end
      private_class_method :turnover_ratio

      private

      def signal_conditions
        <<~SQL.squish
          h1.id IS NOT NULL
          AND h1.offervolume > 0
          AND (CAST(h1.soldtoday AS REAL) / h1.offervolume) >= #{TURNOVER_RATIO_THRESHOLD}
        SQL
      end
    end
  end
end
