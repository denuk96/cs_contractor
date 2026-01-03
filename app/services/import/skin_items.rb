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
        latest_steam_price = (price["pricelatest"] || price["pricelatestsell"] || price["buyordermedian"]).to_f
        latest_steam_order_price = (price["buyorderprice"] || price["buyordermedian"] || price["buyorderavg"]).to_f
        skin_item = SkinItem.upsert(
          {  name: price["markethashname"],
             rarity: skin.rarity,
             wear:,
             souvenir: price["issouvenir"],
             stattrak: price["isstattrak"],
             skin_id: skin.id,
             latest_steam_price:,
             latest_steam_order_price:,
             last_steam_price_updated_at: Time.zone.now,
             metadata: price
          },
          unique_by: :index_skin_items_on_name,
          returning: %w[id]
        )

        SkinItemHistory.upsert(
          {
            skin_item_id: skin_item.first["id"],
            pricelatest: price["pricelatest"],
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
            date: Time.zone.today
          },
          unique_by: %i[skin_item_id date]
        )
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
  end
end
