module Import
  class SkinItems
    URL = "https://api.skinport.com/v1/items?app_id=730&currency=USD".freeze

    def call
      json = fetch_data
      json.each do |price|
        skin = find_skin(price["market_hash_name"])
        if skin.nil?
          Rails.logger.warn("Could not find skin for #{price["market_hash_name"]}")
          next
        end

        # latest_steam_price = price["quantity"].to_i > 9 ? price["median_price"] : nil
        wear = define_wear(price["market_hash_name"])
        SkinItem.upsert(
          {  name: price["market_hash_name"],
             rarity: skin.rarity,
             wear:,
             souvenir: price["market_hash_name"].include?("Souvenir"),
             stattrak: price["market_hash_name"].include?("StatTrak™"),
             skin_id: skin.id
          },
          unique_by: :index_skin_items_on_name
        )
      end
    end

    private

    def find_skin(name)
      raw_name = name.gsub(/\s\([^()]*\)\s*\z/, "")
                     .gsub("Souvenir", "")
                     .gsub("StatTrak™", "")
                     .strip
      # Skin.where("name LIKE ?", "%#{raw_name}%").first
      Skin.where(name: raw_name).first
    end

    def fetch_data
      resp = Faraday.get(URL) do |r|
        r.headers["Accept"] = "application/json"
        r.headers["Accept-Encoding"] = "br"      # required by Skinport
        r.options.open_timeout = 5
        r.options.timeout = 5
      end
      raise "HTTP #{resp.status}" unless resp.success?

      body =
        if resp.headers["content-encoding"]&.include?("br")
          require "brotli"
          Brotli.inflate(resp.body)
        else
          resp.body
        end

      JSON.parse(body)
    end

    def define_wear(name)
      name[/\(([^)]+)\)/, 1]
    end
  end
end
