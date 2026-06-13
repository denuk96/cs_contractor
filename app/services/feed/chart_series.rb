# frozen_string_literal: true

module Feed
  # Builds a Chartkick series for a feed item's mini "why" chart: the metric
  # that drove its signal, over the SkinItems::Signals::RecentHistoryQuery
  # window.
  class ChartSeries
    SERIES_NAMES = {
      "top_signals" => "Buy wall ratio",
      "supply_dry_up" => "Turnover %",
      "buy_order_increase" => "Buy order volume"
    }.freeze

    def initialize(feed_item, history)
      @feed_item = feed_item
      @history = history
    end

    def call
      [{ name: SERIES_NAMES.fetch(feed_item.signal_type), data: history.map { |h| [h.date, metric(h)] } }]
    end

    private

    attr_reader :feed_item, :history

    def metric(history_row)
      value =
        case feed_item.signal_type
        when "top_signals" then ratio(history_row.buyordervolume, history_row.offervolume)
        when "supply_dry_up" then ratio(history_row.soldtoday, history_row.offervolume) * 100
        else history_row.buyordervolume.to_f
        end

      value.round(2)
    end

    def ratio(numerator, denominator)
      return 0.0 if denominator.to_i.zero?

      numerator.to_f / denominator
    end
  end
end
