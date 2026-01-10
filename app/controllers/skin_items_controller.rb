class SkinItemsController < ApplicationController
  def show
    # Join with skins to get the fallback rarity and crates
    @skin_item = SkinItem.joins(:skin).select('skin_items.*, skins.rarity as skin_rarity, skins.collection_name, skins.crates as skin_crates').find(params[:id])
    
    history = @skin_item.skin_item_histories.order(date: :asc)
    latest_history = history.last

    # Turnover Rate History
    @turnover_history = history.map do |h|
      turnover = h.offervolume.to_i > 0 ? (h.soldtoday.to_f / h.offervolume.to_f) * 100 : 0
      [h.date, turnover]
    end
    @current_turnover = @turnover_history.last&.second.to_f

    # Buy Wall Ratio History
    @buy_wall_history = history.map do |h|
      ratio = h.offervolume.to_i > 0 ? (h.buyordervolume.to_f / h.offervolume.to_f) : 0
      [h.date, ratio]
    end
    
    # Current Buy Wall Ratio
    if latest_history&.offervolume.to_i > 0
      @buy_wall_ratio = latest_history.buyordervolume.to_f / latest_history.offervolume.to_f
    else
      @buy_wall_ratio = nil
    end

    # Volume/Price Divergence
    if history.length >= 8
      prev_week_history = history.slice(-8)
      @volume_change = ((latest_history.sold7d.to_f - prev_week_history.sold7d.to_f) / prev_week_history.sold7d.to_f) * 100
      @price_change = ((latest_history.pricelatest.to_f - prev_week_history.pricelatest.to_f) / prev_week_history.pricelatest.to_f) * 100
    else
      @volume_change = nil
      @price_change = nil
    end

    # 0. Supply Runover Dashboard Data (New)
    @supply_runover_data = [
      { name: 'Sold Volume', data: history.pluck(:date, :soldtoday), yAxis: 'volume-axis' },
      { name: 'Offer Volume (Supply)', data: history.pluck(:date, :offervolume), yAxis: 'volume-axis' },
      { name: 'All Markets Quantity', data: history.pluck(:date, :all_markets_quantity), yAxis: 'volume-axis', dataset: { hidden: true } }
    ]

    # 1. Accumulation Dashboard Data (Reverted)
    @accumulation_data = [
      { name: 'Offer Volume (Supply)', data: history.pluck(:date, :offervolume), yAxis: 'volume-axis' },
      { name: 'Buy Orders (Demand)', data: history.pluck(:date, :buyordervolume), yAxis: 'volume-axis' },
      { name: 'Price', data: history.pluck(:date, :pricelatest), yAxis: 'price-axis' }
    ]

    # 2. Elasticity Dashboard Data
    @elasticity_data = [
      { name: 'Buy Wall Ratio', data: @buy_wall_history, yAxis: 'ratio-axis' },
      { name: 'Turnover Rate (%)', data: @turnover_history, yAxis: 'percent-axis' }
    ]

    # 3. Fakeout Dashboard Data
    @fakeout_data = [
      { name: 'Sold Volume', data: history.pluck(:date, :soldtoday), yAxis: 'volume-axis' },
      { name: 'Price', data: history.pluck(:date, :pricelatest), yAxis: 'price-axis' },
      { name: 'All Markets Weighted Median Price', data: history.pluck(:date, :all_markets_weighted_median_price), yAxis: 'price-axis', dataset: { hidden: true } }
    ]

    # 4. Squeeze Chart (God Mode) Data
    @squeeze_data = [
      { name: 'Buy Wall Ratio', data: @buy_wall_history, color: '#198754', yAxis: 'ratio-axis' }, # Green
      { name: 'Offer Volume', data: history.pluck(:date, :offervolume), color: '#dc3545', yAxis: 'volume-axis' }, # Red
      { name: 'Sold Volume', data: history.pluck(:date, :soldtoday), type: 'column', color: '#6c757d', yAxis: 'volume-axis' } # Grey
    ]
  end
end
