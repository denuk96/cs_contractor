module FeedHelper
  # Severity slug per signal, shared by the badge, the group divider and the
  # sparkline so an entry reads as one colour top to bottom.
  SIGNAL_SLUGS = {
    "top_signals" => "moon",
    "supply_dry_up" => "squeeze",
    "buy_order_increase" => "organic"
  }.freeze

  # Chart.js needs a concrete value, so the sparkline takes the dark-theme
  # lift of each severity hue — legible on both grounds.
  SIGNAL_COLORS = {
    "top_signals" => "#f0736f",
    "supply_dry_up" => "#eda100",
    "buy_order_increase" => "#2fbf85"
  }.freeze

  def feed_signal_slug(signal_type)
    SIGNAL_SLUGS.fetch(signal_type, "dead")
  end

  def feed_signal_color(signal_type)
    SIGNAL_COLORS.fetch(signal_type, "#79828f")
  end

  def feed_signal_counts
    @feed_signal_counts ||= FeedItem.group(:signal_type).count
  end

  # Recency, spelled out: the flat list gave no sense of when a signal fired.
  def feed_group_label(date)
    days = (Date.current - date).to_i

    case days
    when 0 then "TODAY"
    when 1 then "YESTERDAY"
    else "#{date} · #{days}D AGO"
    end
  end
end
