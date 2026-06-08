module Import
  # Normalises the multi-market `prices` array from the steamwebapi payload into
  # first-class SkinItemHistoryPrice rows (one per third-party market) plus a
  # synthetic "steam" row carrying Steam's comparable lowest-offer quote, so
  # cross-market queries stay uniform. Shared by the live import
  # (Import::SkinItems#fetch_webapi_data) and the metadata backfill task.
  class MarketPrices
    # Steam's analog to a third-party "offer" (lowest ask), most reliable first.
    STEAM_PRICE_KEYS = %w[pricelatest pricelatestsell pricemedian24h].freeze
    UTC = ActiveSupport::TimeZone["UTC"]

    def self.call(...)
      new(...).call
    end

    def initialize(skin_item_history_id, payload)
      @skin_item_history_id = skin_item_history_id
      @payload = payload || {}
    end

    def call
      rows = market_rows
      steam = steam_row
      rows << steam if steam
      return if rows.empty?

      SkinItemHistoryPrice.upsert_all(rows, unique_by: :idx_sihp_on_history_and_source)
    end

    private

    attr_reader :skin_item_history_id, :payload

    def market_rows
      Array(payload["prices"]).filter_map do |entry|
        source = entry["source"].presence
        price = entry["price"].to_f
        next if source.nil? || price <= 0

        row(
          source: source,
          price: price,
          quantity: entry["quantity"].to_i,
          kind: entry["type"].presence || "offer",
          source_updated_at: parse_time(entry["created_at"])
        )
      end
    end

    def steam_row
      price = STEAM_PRICE_KEYS.filter_map { |key| payload[key] }.map(&:to_f).find(&:positive?)
      return unless price

      row(
        source: SkinItemHistoryPrice::STEAM_SOURCE,
        price: price,
        quantity: payload["offervolume"].to_i,
        kind: "offer",
        source_updated_at: parse_time(payload.dig("priceupdatedat", "date"))
      )
    end

    def row(source:, price:, quantity:, kind:, source_updated_at:)
      now = Time.current
      {
        skin_item_history_id: skin_item_history_id,
        source: source,
        price: price,
        quantity: quantity,
        kind: kind,
        source_updated_at: source_updated_at,
        created_at: now,
        updated_at: now
      }
    end

    # steamwebapi timestamps are UTC ("2026-06-07 08:48:10").
    def parse_time(value)
      return if value.blank?

      UTC.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
