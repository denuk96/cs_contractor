require "rails_helper"

RSpec.describe Import::MarketPrices do
  # steamwebapi repeats a market once per intraday snapshot, so Skinport shows
  # up several times with drifting price/quantity.
  let(:payload) do
    {
      "offervolume" => 100,
      "prices" => [
        { "price" => 0.36, "source" => "csgocom",  "quantity" => 254, "type" => "offer", "created_at" => "2026-07-30 20:13:00" },
        { "price" => 0.47, "source" => "skinport", "quantity" => 739, "type" => "offer", "created_at" => "2026-07-30 03:55:00" },
        { "price" => 0.48, "source" => "skinport", "quantity" => 738, "type" => "offer", "created_at" => "2026-07-30 04:45:20" },
        { "price" => 0.48, "source" => "skinport", "quantity" => 737, "type" => "offer", "created_at" => "2026-07-30 08:39:00" },
        { "price" => 0.54, "source" => "dmarket",  "quantity" => 295, "type" => "offer", "created_at" => nil }
      ]
    }
  end

  describe ".deduped_price_entries" do
    it "keeps the freshest entry per source" do
      entries = described_class.deduped_price_entries(payload)

      expect(entries.map { |e| e["source"] }).to eq(%w[csgocom skinport dmarket])
      expect(entries.find { |e| e["source"] == "skinport" }).to include(
        "quantity" => 737, "created_at" => "2026-07-30 08:39:00"
      )
    end

    it "falls back to the last occurrence when timestamps are missing" do
      payload["prices"] = [
        { "price" => 0.47, "source" => "skinport", "quantity" => 739 },
        { "price" => 0.48, "source" => "skinport", "quantity" => 700 }
      ]

      expect(described_class.deduped_price_entries(payload).map { |e| e["quantity"] }).to eq([700])
    end

    it "drops entries without a source and tolerates a missing prices array" do
      payload["prices"] << { "price" => 0.55, "source" => nil, "quantity" => 999 }

      expect(described_class.deduped_price_entries(payload).size).to eq(3)
      expect(described_class.deduped_price_entries({})).to eq([])
      expect(described_class.deduped_price_entries(nil)).to eq([])
    end
  end

  describe ".total_market_quantity" do
    it "sums one quantity per market plus Steam's offer volume" do
      expect(described_class.total_market_quantity(payload)).to eq(254 + 737 + 295 + 100)
    end

    it "counts only Steam when there are no third-party markets" do
      expect(described_class.total_market_quantity("offervolume" => 42)).to eq(42)
    end
  end

  describe "#call" do
    it "writes one row per market instead of one per snapshot" do
      history = SkinItemHistory.create!(skin_item: create(:skin_item), date: Date.current)

      described_class.call(history.id, payload.merge("pricelatest" => 0.5))

      rows = history.market_prices.order(:source).pluck(:source, :price, :quantity)
      expect(rows).to eq([
        ["csgocom", 0.36, 254],
        ["dmarket", 0.54, 295],
        ["skinport", 0.48, 737],
        [SkinItemHistoryPrice::STEAM_SOURCE, 0.5, 100]
      ])
    end
  end
end
