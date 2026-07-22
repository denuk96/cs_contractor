module MarketOverviewHelper
  # Axis tick formatting per metric unit. Values are raw JS callbacks, which is
  # how chartkick passes options through to Chart.js.
  TICK_CALLBACKS = {
    integer: "function(value) { return value.toLocaleString(); }",
    currency: "function(value) { return '$' + value.toLocaleString(); }",
    percent: "function(value) { return value.toFixed(1) + '%'; }",
    ratio: "function(value) { return value.toFixed(1) + 'x'; }",
    decimal: "function(value) { return value.toFixed(1); }"
  }.freeze

  # Renders an aggregated market metric in the unit its chart uses.
  def market_metric(value, format)
    case format
    when :currency then number_to_currency(value, precision: 0)
    when :percent  then "#{number_with_precision(value, precision: 1)}%"
    when :ratio    then "#{number_with_precision(value, precision: 2)}x"
    when :decimal  then number_with_precision(value, precision: 1)
    else number_with_delimiter(value.round)
    end
  end

  # Single series, single axis, no legend — the heading names the metric.
  def market_chart_library(chart)
    {
      plugins: { legend: { display: false } },
      scales: {
        y: {
          title: { display: true, text: chart[:axis] },
          ticks: { callback: TICK_CALLBACKS.fetch(chart[:unit], TICK_CALLBACKS[:integer]) }
        }
      }
    }
  end
end
