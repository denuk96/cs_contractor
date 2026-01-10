module Import
  class SkinItems
    INVALID_NAMES = [
      "Sticker Slab",
      "Case Key",
      "Music Kit",
      "Capsule Key"
    ].freeze

    def fetch_webapi_data
      json = SteamWebApi.new.fetch_data(game: "cs2")
      json.each do |price|
        next if invalid_name?(price["markethashname"])

        skin = find_skin(price["markethashname"])
        if skin.nil?
          Rails.logger.warn("Could not find skin for #{price["markethashname"]}")
          next
        end
        wear = define_wear(price["markethashname"])
        latest_steam_price = find_valid_price(price, keys: %w[pricelatest pricelatestsell buyordermedian pricerealmedian priceavg24h])
        latest_steam_order_price = find_valid_price(price, keys: %w[buyorderprice buyordermedian buyorderavg])
        skin_item = SkinItem.upsert(
          {  name: price["markethashname"],
             rarity: skin.rarity,
             wear:,
             souvenir: price["issouvenir"],
             stattrak: price["isstattrak"],
             skin_id: skin.id,
             latest_steam_price:,
             latest_steam_order_price:,
             last_steam_price_updated_at: Time.zone.now
          },
          unique_by: :index_skin_items_on_name,
          returning: %w[id]
        )

        all_prices = price["prices"].dup << { "quantity" => price["offervolume"],
                                              "price" => find_valid_price(price, keys: %w[pricerealmedian priceavg24h pricereal]) } # steam
        all_markets_weighted_median_price = calculate_weighted_median(all_prices)

        SkinItemHistory.upsert(
          {
            skin_item_id: skin_item.first["id"],
            pricelatest: latest_steam_price,
            pricemedian: price["pricemedian"],
            pricemedian24h: price["pricemedian24h"],
            pricemedian7d: price["pricemedian7d"],
            pricemedian30d: price["pricemedian30d"],
            pricemedian90d: price["pricemedian90d"],
            sold24h: price["sold24h"],
            sold7d: price["sold7d"],
            sold30d: price["sold30d"],
            sold90d: price["sold90d"],
            soldtotal: price["soldtotal"],
            soldtoday: price["soldtoday"],
            buyordervolume: price["buyordervolume"],
            buyorderprice: price["buyorderprice"],
            buyordermedian: price["buyordermedian"],
            buyorderavg: price["buyorderavg"],
            offervolume: price["offervolume"],
            all_markets_quantity: (price["prices"].sum { |p| p["quantity"] } + price["offervolume"]),
            all_markets_weighted_median_price:,
            date: Time.zone.today,
            metadata: price
          },
          unique_by: %i[skin_item_id date]
        )
        rescue => e
          Rails.logger.warn("SkinItem upsert skipped (id=#{skin_item.inspect}): #{e.class}: #{e.message}")
      end
    end

    def fetch_skinport_data
      json = SkinportApi.new.fetch_data
      json.each do |price|
        next if invalid_name?(price["market_hash_name"])

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
      raw_name = name.gsub("StatTrak™", "")
                     .gsub(/ {2,}/, ' ')
      unless raw_name.include?("Sticker") || raw_name.include?("Graffiti") || raw_name.include?("Holo") || raw_name.include?("Foil")
        raw_name = raw_name.gsub(/\s\([^()]*\)\s*\z/, "")
      end
      unless raw_name.include?("Souvenir Charm") || raw_name.include?("Souvenir Package")
        raw_name = raw_name.gsub("Souvenir", "")
      end
      # Skin.where("name LIKE ?", "%#{raw_name}%").first
      Skin.where(name: raw_name.strip).first
    end

    def define_wear(name)
      name[/\(([^)]+)\)/, 1]
    end

    def invalid_name?(name)
      INVALID_NAMES.any? { |invalid| name.include?(invalid) }
    end

    def calculate_weighted_median(items)
      sanitized = items.map do |i|
        {
          "price" => i["price"].to_f,
          "quantity" => i["quantity"].to_i
        }
      end.reject { |i| i["price"].zero? || i["quantity"].zero? }

      return nil if sanitized.empty?
      return sanitized.first["price"] if sanitized.size >= 1

      sorted = sanitized.sort_by { |i| i["price"] }

      total_qty = sorted.sum { |i| i["quantity"] }
      return 0.0 if total_qty.zero?

      mid_low = (total_qty + 1) / 2.0
      mid_high = (total_qty + 2) / 2.0

      find_price = ->(target) do
        cumulative = 0
        sorted.each do |item|
          cumulative += item["quantity"]
          return item["price"] if cumulative >= target
        end
      end

      (find_price.call(mid_low) + find_price.call(mid_high)) / 2.0
    end

    def find_valid_price(price_data, keys:)
      # Find the first key whose value passes our validation
      valid_key = keys.find do |key|
        val = price_data[key]
        val && valid_price?(val)
      end

      # Return the float value of the valid key, or nil if none are sane
      valid_key ? price_data[valid_key].to_f : nil
    end

    def valid_price?(value, min: 0.01, max: 100_000.0)
      # 1. Ensure it's a number (handles nil or malformed strings)
      num = value.to_f

      # 2. Check if it's Finite (rejects Infinity or NaN)
      return false unless num.finite?

      # 3. Range check: Reject E-notation/outliers
      num >= min && num <= max
    end
  end
end

