# frozen_string_literal: true

module Market
  # Rebuilds `market_daily_stats` for a date range from `skin_item_histories`.
  #
  # Idempotent: the range is deleted and re-inserted in one transaction, so the
  # nightly job can safely re-run recent days (late imports, corrections) and a
  # full backfill can be repeated without duplicating rows.
  class RecalculateDailyStats
    # Dates are processed in chunks so a multi-year backfill never builds one
    # huge insert.
    BATCH_DAYS = 30

    Result = Data.define(:from, :to, :rows_written)

    AGGREGATES = <<~SQL.squish
      skin_item_histories.date,
      COALESCE(skin_items.stattrak, 0),
      COALESCE(skin_items.souvenir, 0),
      COALESCE(skin_items.in_game_store, 0),
      COUNT(*),
      SUM(COALESCE(skin_item_histories.soldtoday, 0)),
      SUM(COALESCE(skin_item_histories.offervolume, 0)),
      SUM(COALESCE(skin_item_histories.buyordervolume, 0)),
      SUM(COALESCE(skin_item_histories.soldtoday, 0) * COALESCE(skin_item_histories.pricelatest, 0)),
      SUM(COALESCE(skin_item_histories.offervolume, 0) * COALESCE(skin_item_histories.pricelatest, 0)),
      SUM(COALESCE(skin_item_histories.pricelatest, 0)),
      SUM(CASE WHEN skin_item_histories.pricelatest IS NULL THEN 0 ELSE 1 END)
    SQL

    GROUP_BY = [
      "skin_item_histories.date",
      "COALESCE(skin_items.stattrak, 0)",
      "COALESCE(skin_items.souvenir, 0)",
      "COALESCE(skin_items.in_game_store, 0)"
    ].freeze

    def initialize(from:, to: Date.current)
      @from = from.to_date
      @to = to.to_date
    end

    def call
      rows_written = 0

      each_batch do |batch_from, batch_to|
        rows = aggregate(batch_from, batch_to)

        MarketDailyStat.transaction do
          MarketDailyStat.between(batch_from, batch_to).delete_all
          MarketDailyStat.insert_all!(rows) if rows.any?
        end

        rows_written += rows.size
      end

      Result.new(from: from, to: to, rows_written: rows_written)
    end

    private

    attr_reader :from, :to

    def each_batch
      batch_from = from

      while batch_from <= to
        batch_to = [batch_from + (BATCH_DAYS - 1), to].min
        yield(batch_from, batch_to)
        batch_from = batch_to + 1
      end
    end

    def aggregate(batch_from, batch_to)
      SkinItemHistory
        .joins(:skin_item)
        .where(date: batch_from..batch_to)
        .group(Arel.sql(GROUP_BY.join(", ")))
        .pluck(Arel.sql(AGGREGATES))
        .map { |row| build_row(row) }
    end

    def build_row(row)
      date, stattrak, souvenir, in_game_store, items_tracked, sold, offers,
        buy_orders, traded_value, listed_value, price_sum, priced_items = row

      {
        date: date.to_date,
        stattrak: boolean(stattrak),
        souvenir: boolean(souvenir),
        in_game_store: boolean(in_game_store),
        items_tracked: items_tracked.to_i,
        sold_volume: sold.to_i,
        offer_volume: offers.to_i,
        buy_order_volume: buy_orders.to_i,
        traded_value: traded_value.to_f,
        listed_value: listed_value.to_f,
        price_sum: price_sum.to_f,
        priced_items: priced_items.to_i
      }
    end

    # SQLite hands booleans back as 0/1.
    def boolean(value)
      ActiveRecord::Type::Boolean.new.cast(value) || false
    end
  end
end
