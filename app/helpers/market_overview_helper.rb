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

  # Chart chrome shared by every chart in the app. Chart.js needs concrete
  # colours, and the server cannot know the reader's theme, so these are picked
  # to sit legibly on both grounds: a translucent grid, and a mid-grey for text
  # that is all but identical in the light and dark text ramps.
  # One hue per series, lifted so it reads on the dark ground. Chartkick does
  # not cycle a short palette — it simply leaves the extra datasets uncoloured —
  # so this runs long enough for the widest chart in the app (one line per
  # third-party market).
  SERIES_PALETTE = %w[
    #5b8ff2 #f0563a #ffab2e #2ec24f #cc4fcc #6f7df5
    #33b5dd #ef6f9b #8dcc33 #e06060 #5d8fc4 #c46fc4 #43ccbb
    #cccc44 #9370e0 #f59a33 #cc3c3c #4fbb87 #7d9bcc #9c4f9e
  ].freeze

  GRID_COLOR = "rgba(125, 135, 150, 0.18)".freeze
  TICK_COLOR = "#79828f".freeze

  def chart_axis(title:, unit: :integer, position: nil, secondary: false)
    axis = {
      type: "linear",
      title: { display: title.present?, text: title, color: TICK_COLOR },
      ticks: { callback: TICK_CALLBACKS.fetch(unit, TICK_CALLBACKS[:integer]), color: TICK_COLOR },
      grid: { color: GRID_COLOR, drawOnChartArea: !secondary }
    }
    axis[:position] = position if position
    axis
  end

  # Chartkick passes a series' :yAxis key straight through, and Chart.js never
  # reads it — so the dual-axis dashboards drew every series against one shared
  # axis while the two named axes sat empty either side. Chart.js reads yAxisID
  # off the dataset, which chartkick *does* forward, so pin them there.
  def pinned_to_axes(series)
    series.map do |entry|
      next entry if entry[:yAxis].blank?

      entry.merge(dataset: (entry[:dataset] || {}).merge(yAxisID: entry[:yAxis]))
    end
  end

  # Chart.js always builds its default "y" scale from the line controller's
  # defaults. When every series is pinned to a named axis, that default would
  # otherwise be drawn as an empty 0-1 axis.
  def named_axes(axes)
    { x: chart_defaults[:scales][:x], y: { display: false } }.merge(axes)
  end

  # The tooltip is inverted against both themes by design, so its colours are
  # theme-independent and can be handed to Chart.js as literals.
  TIP_BG = "#242a32".freeze
  TIP_BORDER = "#2f3843".freeze
  TIP_TEXT = "#ffffff".freeze
  TIP_BODY = "#a9b1bc".freeze

  # A 2px curve with no points and no area fill, over a hairline grid.
  #
  # Interaction is index-mode so that hovering anywhere in the plot picks the
  # nearest date and reports every visible series at it in one tooltip — the
  # crosshair plugin draws the dashed rule that ties them together.
  def chart_defaults
    {
      interaction: { mode: "index", intersect: false, axis: "x" },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: TIP_BG,
          borderColor: TIP_BORDER,
          borderWidth: 1,
          titleColor: TIP_TEXT,
          bodyColor: TIP_BODY,
          titleFont: { size: 11, weight: "700" },
          bodyFont: { size: 11.5 },
          padding: 10,
          cornerRadius: 7,
          displayColors: true,
          boxWidth: 8,
          boxHeight: 8,
          boxPadding: 5
        }
      },
      elements: {
        point: { radius: 0, hitRadius: 12, hoverRadius: 4, hoverBorderWidth: 2 },
        line: { borderWidth: 2, tension: 0.4, fill: false }
      },
      scales: { x: { ticks: { color: TICK_COLOR }, grid: { color: GRID_COLOR } } }
    }
  end

  # Single series, single axis, no legend — the heading names the metric.
  def market_chart_library(chart)
    defaults = chart_defaults
    defaults.merge(scales: defaults[:scales].merge(y: chart_axis(title: chart[:axis], unit: chart[:unit])))
  end
end
