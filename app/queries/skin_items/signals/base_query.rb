# frozen_string_literal: true

module SkinItems
  module Signals
    # Shared scaffolding for "feed signal" queries.
    #
    # Each subclass compares the latest `skin_item_histories` snapshot (h1)
    # against an earlier one (h2) and selects items for which
    # `signal_conditions` holds. Subclasses also expose class-level
    # `signal_type`, `headline` and `details` so `Feed::GenerateEntries` can
    # turn matches into `FeedItem` records without any extra wiring.
    class BaseQuery
      DEFAULT_LIMIT = 100

      def initialize(limit: DEFAULT_LIMIT)
        @limit = limit
      end

      def call
        SkinItem.find_by_sql(sql)
      end

      private

      attr_reader :limit

      def h1_date_subquery
        "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id)"
      end

      def h2_date_subquery
        "(SELECT MIN(date) FROM skin_item_histories WHERE skin_item_id = fi.id)"
      end

      def signal_conditions
        raise NotImplementedError, "#{self.class} must implement #signal_conditions"
      end

      def sql
        <<~SQL
          WITH filtered_items AS (
            SELECT skin_items.*, skins.collection_name, skins.rarity AS skin_rarity
            FROM skin_items
            JOIN skins ON skins.id = skin_items.skin_id
            WHERE skin_items.souvenir = 0
          )
          SELECT
            fi.*,
            h1.date as current_date,
            h2.date as prev_date,
            h1.soldtoday as current_soldtoday,
            h1.buyordervolume as current_buyordervolume,
            h1.offervolume as current_offervolume,
            h1.pricelatest as current_price,
            h1.buyorderprice as current_buyorderprice,
            h2.pricelatest as prev_price,
            h2.soldtoday as prev_soldtoday,
            h2.buyordervolume as prev_buyordervolume,
            h2.offervolume as prev_offervolume
          FROM filtered_items fi
          LEFT JOIN skin_item_histories h1 ON h1.skin_item_id = fi.id AND h1.date = #{h1_date_subquery}
          LEFT JOIN skin_item_histories h2 ON h2.skin_item_id = fi.id AND h2.date = #{h2_date_subquery}
          WHERE #{signal_conditions}
          ORDER BY h1.date DESC
          LIMIT #{limit}
        SQL
      end
    end
  end
end
