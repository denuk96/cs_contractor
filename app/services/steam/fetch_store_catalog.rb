module Steam
  # Builds the catalog of items currently sold in the CS2 in-game store by
  # cross-referencing Valve's official asset prices (GetAssetPrices) - which
  # lists the `def_index` of every asset currently on sale - with the
  # community item database, which maps `def_index` to `market_hash_name`.
  class FetchStoreCatalog
    ALL_ITEMS_URL = "https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/all.json".freeze

    def initialize(client: Steam::Client.new)
      @client = client
    end

    def call
      def_indexes = active_def_indexes

      all_items.select { |item| def_indexes.include?(item["def_index"].to_s) }
    end

    private

    # def_index values (as strings) of assets currently sold in the CS2
    # in-game store, per Valve's official asset prices.
    def active_def_indexes
      assets = @client.asset_prices["assets"] || []
      assets.filter_map { |asset| asset["class"]&.find { |attr| attr["name"] == "def_index" } }
            .map { |attr| attr["value"] }
            .to_set
    end

    def all_items
      resp = Faraday.get(ALL_ITEMS_URL) do |r|
        r.headers["Accept"] = "application/json"
      end
      raise "HTTP #{resp.status}" unless resp.success?

      JSON.parse(resp.body).values
    end
  end
end
