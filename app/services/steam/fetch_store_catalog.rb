module Steam
  # Builds the catalog of items currently sold in the CS2 in-game store by
  # cross-referencing Valve's official asset prices (GetAssetPrices) with
  # Valve's asset class info (GetAssetClassInfo) for item names and icons.
  class FetchStoreCatalog
    ICON_BASE_URL = "https://community.cloudflare.steamstatic.com/economy/image".freeze
    CLASS_INFO_BATCH_SIZE = 50

    def initialize(client: Steam::Client.new)
      @client = client
    end

    def call
      assets = @client.asset_prices["assets"] || []
      store_prices = assets.to_h { |asset| [asset["classid"], prices_for(asset)] }

      store_prices.keys.each_slice(CLASS_INFO_BATCH_SIZE).flat_map do |classids|
        class_info = @client.asset_class_info(classids)

        classids.filter_map do |classid|
          item = class_info[classid]
          next unless item

          {
            "classid" => classid,
            "name" => item["name"],
            "market_hash_name" => item["market_hash_name"],
            "icon_url" => "#{ICON_BASE_URL}/#{item['icon_url']}"
          }.merge(store_prices[classid])
        end
      end
    end

    private

    def prices_for(asset)
      original_price = asset.dig("original_prices", "USD")

      {
        "price_usd" => asset.dig("prices", "USD").fdiv(100),
        "original_price_usd" => original_price&.fdiv(100)
      }
    end
  end
end
