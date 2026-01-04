

class CsvExportService
  def initialize(items)
    @items = items
  end

  def call
    CSV.generate(headers: true) do |csv|
      csv << headers
      @items.each do |item|
        csv << row_data(item)
      end
    end
  end

  private

  def headers
    [
      'Name', 'Collection', 'Rarity', 'Wear', 'Latest Price',
      'Price Change', 'Sold Today', 'Sold Volume Change',
      'Offer Volume', 'Offer Change', 'Turnover Rate (%)',
      'Buy Order Volume', 'Buy Order Change', 'Buy Wall Ratio (x)',
      'Comparison Start', 'Comparison End'
    ]
  end

  def row_data(item)
    [
      item.name,
      collection_name(item),
      item.skin_rarity || item.rarity,
      item.wear,
      item.latest_steam_price,
      calculate_change(item.current_price, item.prev_price),
      item.current_soldtoday,
      calculate_change(item.current_soldtoday, item.prev_soldtoday),
      item.current_offervolume,
      calculate_change(item.current_offervolume, item.prev_offervolume),
      turnover_rate(item),
      item.current_buyordervolume,
      calculate_change(item.current_buyordervolume, item.prev_buyordervolume),
      buy_wall_ratio(item),
      item.prev_date,
      item.current_date
    ]
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
