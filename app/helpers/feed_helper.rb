module FeedHelper
  SIGNAL_BADGE_CLASSES = {
    "top_signals" => "bg-danger",
    "supply_dry_up" => "bg-warning text-dark",
    "buy_order_increase" => "bg-success"
  }.freeze

  def feed_signal_badge_class(signal_type)
    SIGNAL_BADGE_CLASSES.fetch(signal_type, "bg-secondary")
  end
end
