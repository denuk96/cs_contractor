
class SteamWebApi
  BASE_URL = "https://www.steamwebapi.com/steam/api/items".freeze

  def fetch_data(params = {})
    resp = Faraday.get(BASE_URL) do |r|
      r.headers["Accept"] = "application/json"
      r.params["key"] = ENV["STEAM_WEB_API_KEY"]
      r.params.merge!(params)
    end
    raise "HTTP #{resp.status}. Response: #{resp.inspect}" unless resp.success?

    JSON.parse(resp.body)
  end
end

