class SkinItemsController < ApplicationController
  def show
    @skin_item = SkinItem.find(params[:id])
    history = @skin_item.skin_item_histories.order(date: :asc)
    latest_history = history.last

    # Turnover Rate
    @turnover_history = history.map do |h|
      turnover = h.offervolume.to_i > 0 ? (h.soldtoday.to_f / h.offervolume.to_f) * 100 : 0
      [h.date, turnover]
    end
    @current_turnover = @turnover_history.last&.second.to_f

    # Volume/Price Divergence
    if history.length >= 8
      prev_week_history = history.slice(-8)
      @volume_change = ((latest_history.sold7d.to_f - prev_week_history.sold7d.to_f) / prev_week_history.sold7d.to_f) * 100
      @price_change = ((latest_history.pricelatest.to_f - prev_week_history.pricelatest.to_f) / prev_week_history.pricelatest.to_f) * 100
    else
      @volume_change = nil
      @price_change = nil
    end

    # Buy Wall
    if latest_history&.offervolume.to_i > 0
      @buy_wall_ratio = latest_history.buyordervolume.to_f / latest_history.offervolume.to_f
    else
      @buy_wall_ratio = nil
    end

    # Chart Data
    @chart_data = [
      { name: 'Price', data: history.pluck(:date, :pricelatest), yAxis: 'price-axis' },
      { name: 'Buy Orders', data: history.pluck(:date, :buyordervolume), yAxis: 'volume-axis' },
      { name: 'Sold', data: history.pluck(:date, :soldtoday), yAxis: 'volume-axis' },
      { name: 'Offers', data: history.pluck(:date, :offervolume), yAxis: 'volume-axis' },
      { name: 'Turnover Rate', data: @turnover_history, yAxis: 'turnover-axis' }
    ]
  end
end
