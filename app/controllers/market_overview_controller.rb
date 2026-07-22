class MarketOverviewController < ApplicationController
  # One metric per chart, one y-axis per chart: a percentage and a six-figure
  # volume share no scale, so they never share a plot. Colors are fixed per
  # metric (a metric keeps its hue in the totals and per-item views) and taken
  # in order from a CVD-validated categorical palette.
  CHARTS = [
    { metric: :sold_volume, title: "Sold Volume", unit: :integer, axis: "Units Sold", color: "#2a78d6",
      hint: "Total units sold across every tracked item each day. Read it against Items Tracked below — a jump in coverage lifts this line without any real demand change." },
    { metric: :offer_volume, title: "Offer Volume (Supply)", unit: :integer, axis: "Listings", color: "#eb6834",
      hint: "Total listings on the market. A sustained decline market-wide means supply is drying up everywhere, not just on a single item — usually the precondition for a broad price run." },
    { metric: :buy_order_volume, title: "Buy Order Count (Demand)", unit: :integer, axis: "Buy Orders", color: "#1baf7a",
      hint: "Total open buy orders. Rising buy orders while supply falls is market-wide accumulation; both falling together is money leaving the market." },
    { metric: :buy_wall_ratio, title: "Buy Wall Ratio", unit: :ratio, axis: "Buy Orders per Listing", color: "#eda100",
      hint: "Formula: total Buy Orders / total Offer Volume. How many buyers are queued behind every listing — the market-wide version of the squeeze signal." },
    { metric: :turnover_rate, title: "Turnover Rate", unit: :percent, axis: "Turnover (%)", color: "#e87ba4",
      hint: "Formula: total Sold / total Offer Volume. How fast the whole market eats through its own supply each day. Under 5% the market is dead; a sharp climb means supply is vanishing faster than it is relisted." },
    { metric: :traded_value, title: "Traded Value", unit: :currency, axis: "USD", color: "#008300",
      hint: "Sold units x latest price: the money that actually changed hands that day." },
    { metric: :listed_value, title: "Listed Value", unit: :currency, axis: "USD", color: "#4a3aa7",
      hint: "Listings x latest price: the money being asked for. Traded value rising while this falls means real demand rather than repricing." },
    { metric: :avg_price, title: "Average Price", unit: :currency, axis: "USD", color: "#e34948",
      hint: "Mean latest price across tracked items. Shifts here can come from the mix of items tracked, not only from prices moving." },
    { metric: :items_tracked, title: "Items Tracked", unit: :integer, axis: "Items", color: "#52514e",
      hint: "How many items had a snapshot that day. Jumps here move every total above, so check this before reading a spike as market movement." }
  ].freeze

  # Same metrics divided by coverage, so a day with more tracked items stays
  # comparable to one with fewer.
  PER_ITEM_CHARTS = [
    { metric: :sold_per_item, title: "Sold per Item", unit: :decimal, axis: "Units", color: "#2a78d6",
      hint: "Sold Volume / Items Tracked." },
    { metric: :offers_per_item, title: "Offers per Item", unit: :decimal, axis: "Listings", color: "#eb6834",
      hint: "Offer Volume / Items Tracked." },
    { metric: :buy_orders_per_item, title: "Buy Orders per Item", unit: :decimal, axis: "Buy Orders", color: "#1baf7a",
      hint: "Buy Order Count / Items Tracked." }
  ].freeze

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
    @charts = CHARTS.map { |chart| chart.merge(data: series(chart[:metric])) }
    @per_item_charts = PER_ITEM_CHARTS.map { |chart| chart.merge(data: series(chart[:metric])) }
  end

  private

  # Latest snapshot vs the first one in range, so each tile shows the move across
  # the whole period rather than a fixed lookback.
  def build_kpis
    return [] if @latest.blank?

    previous = @days.first
    previous = nil if previous == @latest

    CHARTS.map { |chart| kpi(chart, previous) }
  end

  def kpi(chart, previous)
    current  = @latest.public_send(chart[:metric])
    baseline = previous&.public_send(chart[:metric])
    change   = baseline.to_f.positive? ? ((current - baseline) / baseline.to_f) * 100 : nil

    { label: chart[:title], value: current, format: chart[:unit], change: change, compared_to: previous&.date }
  end

  def series(metric)
    @days.map { |day| [day.date, day.public_send(metric).round(2)] }
  end
end
