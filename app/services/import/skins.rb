module Import
  class Skins
    URL = "https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/skins.json".freeze

    def call
      json = fetch_data
      json.each do |skin|
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
            category: skin.dig("category", "name"),
            min_float: skin["min_float"],
            max_float: skin["max_float"],
            wears: skin["wear"]&.map { |w| w["name"] } || [],
            crates: skin["crates"]&.map { |c| c["name"] } || [],
            weapon: skin["weapon"]
          },
          unique_by: :index_skins_on_object_id
        )
      rescue => e
        Rails.logger.warn("Skin upsert skipped (id=#{skin['id'].inspect}): #{e.class}: #{e.message}")
        next
      end
    end

    private

    def fetch_data
      resp = Faraday.get(URL) do |r|
        r.headers["Accept"] = "application/json"
        r.options.open_timeout = 5
        r.options.timeout = 5
      end
      raise "HTTP #{resp.status}" unless resp.success?

      JSON.parse(resp.body)
    end
  end
end
