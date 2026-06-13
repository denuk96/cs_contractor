module Steam
  # Authenticated client for Valve's official Steam Web API, used to read
  # Valve's own CS2 asset prices.
  class Client
    BASE_URL = "https://api.steampowered.com".freeze

    def initialize(api_key: ENV["STEAM_API_KEY"], timeout: 10, open_timeout: 5, retries: 3, retry_backoff: 5)
      @api_key = api_key
      @timeout = timeout
      @open_timeout = open_timeout
      @retries = retries
      @retry_backoff = retry_backoff
    end

    # Official in-game store prices for all assets, each tagged with its
    # item definition index (`def_index`) under the `class` attributes.
    def asset_prices(appid: 730, language: "english", currency: nil)
      params = { appid:, language: }
      params[:currency] = currency if currency
      get("/ISteamEconomy/GetAssetPrices/v1/", **params)
    end

    private

    def get(path, **params)
      resp = connection.get(path) do |r|
        r.params = params.merge(key: @api_key)
        r.headers["Accept"] = "application/json"
      end

      raise "HTTP #{resp.status}" unless resp.success?

      body = JSON.parse(resp.body)
      body.fetch("result") { raise "Unexpected Steam API response: #{resp.body}" }
    end

    def connection
      Faraday.new(url: BASE_URL) do |f|
        # Retry on rate limits and common network errors (including timeouts)
        f.request :retry,
                  max: @retries,
                  interval: @retry_backoff,
                  interval_randomness: 0.5,
                  backoff_factor: 5.0,
                  retry_statuses: [429, 500, 502, 503, 504],
                  methods: [:get],
                  exceptions: [
                    Faraday::ConnectionFailed,
                    Faraday::TimeoutError,
                    Faraday::ServerError,
                    Net::OpenTimeout,
                    Net::ReadTimeout,
                    Faraday::TooManyRequestsError
                  ]

        f.options.timeout = @timeout
        f.options.open_timeout = @open_timeout

        # Keep raise_error to bubble up after retries are exhausted
        f.response :raise_error rescue nil
        f.adapter Faraday.default_adapter
      end
    end
  end
end
