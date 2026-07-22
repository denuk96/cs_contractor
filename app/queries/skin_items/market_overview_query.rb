# frozen_string_literal: true

module SkinItems
  # Market-wide, day-by-day aggregate of `skin_item_histories`.
  #
  # The show page slices one item's history; this rolls every tracked item into
  # a single snapshot per day (supply, demand, sold volume, money moved) so the
  # overview page can chart where the market as a whole is heading.
  #
  # Without an explicit range it returns the full recorded history.
  #
  # Note: coverage is not constant — items get added to the tracker over time —
  # so `items_tracked` is returned alongside the totals, and every metric also
  # has a per-item variant that stays comparable across days.
  class MarketOverviewQuery
    Result = Data.define(:days, :start_date, :end_date, :latest_date)

    # One aggregated market day.
    Day = Data.define(
      :date,
      :items_tracked,
      :sold_volume,
      :offer_volume,
      :buy_order_volume,
      :traded_value,
      :listed_value,
      :avg_price
    ) do
      # Share of the listed supply that changed hands that day.
      def turnover_rate
        offer_volume.positive? ? (sold_volume.to_f / offer_volume) * 100 : 0.0
      end

      # Standing buy orders per listed offer — the market's "buy wall".
      def buy_wall_ratio
        offer_volume.positive? ? buy_order_volume.to_f / offer_volume : 0.0
      end

      def sold_per_item
        items_tracked.positive? ? sold_volume.to_f / items_tracked : 0.0
      end

      def offers_per_item
        items_tracked.positive? ? offer_volume.to_f / items_tracked : 0.0
      end

      def buy_orders_per_item
        items_tracked.positive? ? buy_order_volume.to_f / items_tracked : 0.0
      end
    end

    AGGREGATES = <<~SQL.squish
      skin_item_histories.date,
      COUNT(*),
      SUM(COALESCE(skin_item_histories.soldtoday, 0)),
      SUM(COALESCE(skin_item_histories.offervolume, 0)),
      SUM(COALESCE(skin_item_histories.buyordervolume, 0)),
      SUM(COALESCE(skin_item_histories.soldtoday, 0) * COALESCE(skin_item_histories.pricelatest, 0)),
      SUM(COALESCE(skin_item_histories.offervolume, 0) * COALESCE(skin_item_histories.pricelatest, 0)),
      AVG(skin_item_histories.pricelatest)
    SQL

    # `stattrak`, `souvenir` and `in_game_store` accept "true"/"false" (blank = any).
    def initialize(start_date: nil, end_date: nil, stattrak: nil, souvenir: "false", in_game_store: nil)
      @start_date = start_date
      @end_date = end_date
      @stattrak = stattrak
      @souvenir = souvenir
      @in_game_store = in_game_store
    end

    def call
      Result.new(days: days, start_date: resolved_start_date, end_date: resolved_end_date, latest_date: latest_date)
    end

    private

    attr_reader :start_date, :end_date, :stattrak, :souvenir, :in_game_store

    def days
      return [] if resolved_end_date.blank?

      scope
        .where(date: resolved_start_date..resolved_end_date)
        .group(:date)
        .order(:date)
        .pluck(Arel.sql(AGGREGATES))
        .map { |row| build_day(row) }
    end

    def build_day(row)
      date, items_tracked, sold, offers, buy_orders, traded_value, listed_value, avg_price = row

      Day.new(
        date: to_date(date),
        items_tracked: items_tracked.to_i,
        sold_volume: sold.to_i,
        offer_volume: offers.to_i,
        buy_order_volume: buy_orders.to_i,
        traded_value: traded_value.to_f,
        listed_value: listed_value.to_f,
        avg_price: avg_price.to_f
      )
    end

    def scope
      @scope ||= begin
        filters = { stattrak: boolean(stattrak), souvenir: boolean(souvenir), in_game_store: boolean(in_game_store) }
                  .compact

        filters.empty? ? SkinItemHistory.all : SkinItemHistory.joins(:skin_item).where(skin_items: filters)
      end
    end

    # The market's last snapshot, used as the default window anchor: history is
    # imported in batches, so "today" is often ahead of the freshest data.
    def latest_date
      return @latest_date if defined?(@latest_date)

      @latest_date = to_date(scope.maximum(:date))
    end

    def earliest_date
      return @earliest_date if defined?(@earliest_date)

      @earliest_date = to_date(scope.minimum(:date))
    end

    def resolved_end_date
      @resolved_end_date ||= parse_date(end_date) || latest_date
    end

    # Unfiltered, the window spans the entire recorded history.
    def resolved_start_date
      @resolved_start_date ||= parse_date(start_date) || earliest_date
    end

    def parse_date(value)
      return value if value.is_a?(Date)

      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
    alias to_date parse_date

    def boolean(value)
      case value.to_s
      when "true", "1"  then true
      when "false", "0" then false
      end
    end
  end
end
