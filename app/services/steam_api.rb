class SteamApi
  BASE_URL = "https://steamcommunity.com/market/priceoverview".freeze

  def self.price_overview(market_hash_name, currency: 1, appid: 730, timeout: 10, open_timeout: 5)
    resp = connection(timeout:, open_timeout:).get do |r|
      r.params = {
        currency: currency,
        appid: appid,
        market_hash_name: market_hash_name
      }
      r.headers["Accept"] = "application/json"
    end

    raise "HTTP #{resp.status}" unless resp.success?

    body = JSON.parse(resp.body, symbolize_names: true)
    unless body.is_a?(Hash) && body.key?(:success)
      raise "Unexpected Steam API response: #{resp.body}"
    end

    body
  end

  def self.connection(timeout:, open_timeout:, retries: 3, retry_backoff: 5)
    Faraday.new(url: BASE_URL) do |f|
      # Retry on rate limits and common network errors (including timeouts)
      f.request :retry,
                max: retries,
                interval: retry_backoff,
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

      f.options.timeout = timeout
      f.options.open_timeout = open_timeout

      # Keep raise_error to bubble up after retries are exhausted
      f.response :raise_error rescue nil
      f.adapter Faraday.default_adapter
    end
  end
  private_class_method :connection
end
