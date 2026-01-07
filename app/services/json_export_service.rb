class JsonExportService
  def initialize(items)
    @items = items
  end

  def call
    @items.map { |item| item_data(item) }.to_json
  end

  private

  def item_data(item)
    {
      name: item.name,
      collection: collection_name(item),
      rarity: item.skin_rarity || item.rarity,
      wear: item.wear,
      latest_price: item.latest_steam_price,
      price_change: calculate_change(item.current_price, item.prev_price),
      sold_today: item.current_soldtoday,
      sold_volume_change: calculate_change(item.current_soldtoday, item.prev_soldtoday),
      offer_volume: item.current_offervolume,
      offer_change: calculate_change(item.current_offervolume, item.prev_offervolume),
      turnover_rate: turnover_rate(item),
      buy_order_volume: item.current_buyordervolume,
      buy_order_change: calculate_change(item.current_buyordervolume, item.prev_buyordervolume),
      buy_wall_ratio: buy_wall_ratio(item),
      comparison_start: item.prev_date,
      comparison_end: item.current_date
    }
  end

  # Helper methods to safely extract data, mirroring view logic.
  def collection_name(item)
    name = item.collection_name
    if name.blank? && item.respond_to?(:skin_crates) && item.skin_crates.present?
      crates = JSON.parse(item.skin_crates) rescue []
      name = crates.first
    end
    name
  end

  def turnover_rate(item)
    return nil if item.current_offervolume.to_i.zero?

    (item.current_soldtoday.to_f / item.current_offervolume.to_f) * 100
  end

  def buy_wall_ratio(item)
    return nil if item.current_offervolume.to_i.zero?

    item.current_buyordervolume.to_f / item.current_offervolume.to_f
  end

  def calculate_change(current, prev)
    return nil if current.nil? || prev.nil?

    current.to_f - prev.to_f
  end
end
