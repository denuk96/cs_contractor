class MarketOverviewController < ApplicationController
  def index
    result = SkinItems::MarketOverviewQuery.new(
      start_date: params[:start_date],
      end_date: params[:end_date],
      stattrak: params[:stattrak],
      souvenir: params[:souvenir] || "false",
      in_game_store: params[:in_game_store]
    ).call

    @days        = result.days
    @start_date  = result.start_date
    @end_date    = result.end_date
    @latest_date = result.latest_date
    @latest      = @days.last

    @kpis = build_kpis
    build_chart_series
  end

  private

  # Latest snapshot vs the first one in range, so each tile shows the move across
  # the whole period rather than a fixed lookback.
  def build_kpis
    return [] if @latest.blank?

    previous = @days.first
    previous = nil if previous == @latest

    [
      kpi("Sold Volume", :sold_volume, previous, format: :integer),
      kpi("Offer Volume (Supply)", :offer_volume, previous, format: :integer),
      kpi("Buy Orders (Demand)", :buy_order_volume, previous, format: :integer),
      kpi("Buy Wall Ratio", :buy_wall_ratio, previous, format: :ratio),
      kpi("Turnover Rate", :turnover_rate, previous, format: :percent),
      kpi("Traded Value", :traded_value, previous, format: :currency),
      kpi("Listed Value", :listed_value, previous, format: :currency),
      kpi("Items Tracked", :items_tracked, previous, format: :integer)
    ]
  end

  def kpi(label, metric, previous, format:)
    current  = @latest.public_send(metric)
    baseline = previous&.public_send(metric)
    change   = baseline.to_f.positive? ? ((current - baseline) / baseline.to_f) * 100 : nil

    { label: label, value: current, format: format, change: change, compared_to: previous&.date }
  end

  def build_chart_series
    @sold_volume_data = [
      { name: "Sold Volume (total)", data: series(:sold_volume), yAxis: "volume-axis" },
      { name: "Sold per Item (avg)", data: series(:sold_per_item, round: 2), yAxis: "avg-axis" }
    ]

    @offer_volume_data = [
      { name: "Offer Volume (total)", data: series(:offer_volume), yAxis: "volume-axis" },
      { name: "Offers per Item (avg)", data: series(:offers_per_item, round: 2), yAxis: "avg-axis" }
    ]

    @buy_order_data = [
      { name: "Buy Orders (total)", data: series(:buy_order_volume), yAxis: "volume-axis" },
      { name: "Buy Orders per Item (avg)", data: series(:buy_orders_per_item, round: 2), yAxis: "avg-axis" }
    ]

    @buy_wall_data = [
      { name: "Buy Wall Ratio", data: series(:buy_wall_ratio, round: 2), color: "#198754", yAxis: "ratio-axis" },
      { name: "Offer Volume", data: series(:offer_volume), color: "#dc3545", yAxis: "volume-axis" }
    ]

    @turnover_data = [
      { name: "Turnover Rate (%)", data: series(:turnover_rate, round: 2), yAxis: "percent-axis" },
      { name: "Sold Volume", data: series(:sold_volume), type: "column", color: "#6c757d", yAxis: "volume-axis" }
    ]

    @value_data = [
      { name: "Traded Value (Sold x Price)", data: series(:traded_value, round: 2), yAxis: "money-axis" },
      { name: "Listed Value (Supply x Price)", data: series(:listed_value, round: 2), yAxis: "listed-axis" },
      { name: "Average Price", data: series(:avg_price, round: 2), yAxis: "price-axis", dataset: { hidden: true } }
    ]

    @coverage_data = [
      { name: "Items Tracked", data: series(:items_tracked) }
    ]
  end

  def series(metric, round: nil)
    @days.map do |day|
      value = day.public_send(metric)
      [day.date, round ? value.round(round) : value]
    end
  end
end
