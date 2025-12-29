
class SteamWebApi
  BASE_URL = "https://www.steamwebapi.com/steam/api".freeze

  def fetch_data(params = {})
    resp = Faraday.get("#{BASE_URL}/items") do |r|
      r.headers["Accept"] = "application/json"
      r.params["key"] = ENV["STEAM_WEB_API_KEY"]
      r.params.merge!(params)
    end
    raise "HTTP #{resp.status}. Response: #{resp.inspect}" unless resp.success?

    JSON.parse(resp.body)
  end

  def orders_activity(market_hash_name)
    resp = Faraday.get("#{BASE_URL}/itemordersactivity") do |r|
      r.headers["Accept"] = "application/json"
      r.params["key"] = ENV["STEAM_WEB_API_KEY"]
      r.params.merge!({ market_hash_name: })
    end
    raise "HTTP #{resp.status}. Response: #{resp.inspect}" unless resp.success?

    JSON.parse(resp.body)
  end
end

