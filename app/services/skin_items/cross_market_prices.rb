# frozen_string_literal: true

module SkinItems
  # Builds the cross-market views for the show page from SkinItemHistoryPrice:
  # - `series`: one line per market (incl. Steam), day by day, for the chart.
  # - `discrepancy`: each third-party market's % difference from Steam in the
  #   latest snapshot, for the table.
  class CrossMarketPrices
    STEAM = SkinItemHistoryPrice::STEAM_SOURCE

    Result = Data.define(:series, :discrepancy, :steam_reference_price, :snapshot_date)

    def initialize(skin_item, latest_history: nil)
      @skin_item = skin_item
      @latest_history = latest_history
    end

    def call
      Result.new(
        series: series,
        discrepancy: discrepancy,
        steam_reference_price: steam_reference_price,
        snapshot_date: latest_history&.date
      )
    end

    private

    attr_reader :skin_item

    def latest_history
      @latest_history ||= skin_item.skin_item_histories.order(:date).last
    end

    # One series per market: { name:, data: [[date, price], ...] }.
    def series
      rows = SkinItemHistoryPrice
             .joins(:skin_item_history)
             .where(skin_item_histories: { skin_item_id: skin_item.id })
             .order("skin_item_histories.date ASC")
             .pluck("skin_item_history_prices.source", "skin_item_histories.date", "skin_item_history_prices.price")

      rows.group_by { |source, _date, _price| source }
          .map { |source, grouped| { name: source.titleize, data: grouped.map { |_s, date, price| [date, price] } } }
    end

    def latest_prices
      @latest_prices ||= latest_history ? latest_history.market_prices.to_a : []
    end

    # Steam's quote in the latest snapshot; falls back to the history column.
    def steam_reference_price
      return @steam_reference_price if defined?(@steam_reference_price)

      @steam_reference_price =
        latest_prices.find { |p| p.source == STEAM }&.price || latest_history&.pricelatest
    end

    def discrepancy
      ref = steam_reference_price

      latest_prices
        .reject { |p| p.source == STEAM }
        .sort_by(&:price)
        .map do |p|
          diff = ref.to_f > 0 ? ((p.price - ref) / ref) * 100 : nil
          { source: p.source, price: p.price, quantity: p.quantity, diff_percent: diff }
        end
    end
  end
end
