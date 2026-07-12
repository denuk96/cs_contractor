require "tempfile"

class SteamWebApi
  BASE_URL = "https://www.steamwebapi.com/steam/api".freeze

  # Streams the (very large) items payload as newline-delimited JSON straight to
  # a tempfile on disk, then yields one parsed item at a time. This keeps peak
  # heap at a single record instead of holding the whole response String *and*
  # the fully-parsed array at once — that double-peak was getting the price
  # import OOM-killed (SIGKILL / signal 9). Returns an Enumerator with no block.
  def each_item(params = {})
    return enum_for(:each_item, params) unless block_given?

    processed = 0
    Tempfile.create(%w[steam_items .ndjson], binmode: true) do |file|
      stream_items(file, params)
      file.rewind

      # Guard against the server ignoring format=ndjson and handing back a plain
      # JSON array — reading that line-by-line would silently import nothing.
      head = file.read(64).to_s.lstrip
      file.rewind
      raise "SteamWebApi /items returned a JSON array, expected ndjson" if head.start_with?("[")

      file.each_line do |line|
        line.strip!
        next if line.empty?

        yield JSON.parse(line.force_encoding(Encoding::UTF_8))
        processed += 1
      end
    end

    # A healthy /items response is always thousands of rows. Zero means an empty
    # or truncated body, which would otherwise look like a successful no-op
    # import and silently skip a whole price cycle — fail loudly so the run is
    # marked failed (and alerted) instead of losing an update.
    raise "SteamWebApi /items produced no items (empty or truncated response)" if processed.zero?

    processed
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

  private

  # Downloads /items in ndjson format, writing each chunk to disk as it arrives
  # (on_data) so the response body never accumulates on the Ruby heap.
  def stream_items(file, params)
    resp = Faraday.get("#{BASE_URL}/items") do |r|
      r.headers["Accept"] = "application/x-ndjson"
      r.params["key"] = ENV["STEAM_WEB_API_KEY"]
      r.params["format"] = "ndjson"
      r.params.merge!(params)
      r.options.on_data = proc { |chunk, *| file.write(chunk) }
    end
    raise "SteamWebApi /items HTTP #{resp.status}" unless resp.success?

    file.flush
  end
end
