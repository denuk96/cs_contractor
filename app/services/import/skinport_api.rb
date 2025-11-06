class Import
  class SkinportApi
    URL = "https://api.skinport.com/v1/items?app_id=730&currency=USD".freeze

    def fetch_data
      resp = Faraday.get(URL) do |r|
        r.headers["Accept"] = "application/json"
        r.headers["Accept-Encoding"] = "br" # required by Skinport
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
  end
end
