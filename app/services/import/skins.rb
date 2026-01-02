module Import
  class Skins
    # https://github.com/ByMykel/CSGO-API

    def call
      Skin::ITEM_TYPES.each do |type|
        fetch_data(type:).each do |skin|
          skin = skin.is_a?(Hash) ? skin : skin[1]

          collection = skin["collections"]&.first
          collection_name = collection&.dig("name")
          Skin.upsert(
            {
              name: skin["name"],
              object_id: skin["id"],
              collection_name: collection_name,
              rarity: skin.dig("rarity", "name"),
              stattrak: skin["stattrak"],
              souvenir: skin["souvenir"],
              category: skin.dig("category", "name") || type,
              min_float: skin["min_float"],
              max_float: skin["max_float"],
              wears: skin["wear"]&.map { |w| w["name"] } || [],
              crates: skin["crates"]&.map { |c| c["name"] } || [],
              weapon: skin["weapon"]
            },
            unique_by: :index_skins_on_object_id
          )
        rescue => e
          Rails.logger.warn("Skin upsert skipped (id=#{skin.inspect}): #{e.class}: #{e.message}")
          next
        end
      end
    end

    private

    def fetch_data(type:)
      url = "https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/#{type}.json"
      resp = Faraday.get(url) do |r|
        r.headers["Accept"] = "application/json"
      end
      raise "HTTP #{resp.status}" unless resp.success?

      JSON.parse(resp.body)
    end
  end
end
