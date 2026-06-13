class FeedController < ApplicationController
  def index
    scope = FeedItem.includes(skin_item: :skin).recent_first
    scope = scope.where(signal_type: params[:signal_type]) if FeedItem.signal_types.key?(params[:signal_type])

    @feed_items = scope.page(params[:page]).per(50)
    @chart_series = build_chart_series(@feed_items)
  end

  private

  def build_chart_series(feed_items)
    histories = SkinItems::Signals::RecentHistoryQuery.new(feed_items.map(&:skin_item_id)).call

    feed_items.to_h do |feed_item|
      [feed_item.id, Feed::ChartSeries.new(feed_item, histories.fetch(feed_item.skin_item_id, [])).call]
    end
  end
end
