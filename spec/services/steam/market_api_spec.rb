require "rails_helper"

RSpec.describe Steam::MarketApi do
  describe ".price_overview" do
    it "returns the parsed price overview for a market hash name" do
      stub_request(:get, "https://steamcommunity.com/market/priceoverview")
        .with(query: { currency: "1", appid: "730", market_hash_name: "AK-47 | Redline (Field-Tested)" })
        .to_return(
          status: 200,
          body: { success: true, lowest_price: "$10.00", volume: "100", median_price: "$11.00" }.to_json
        )

      result = described_class.price_overview("AK-47 | Redline (Field-Tested)")

      expect(result).to eq(success: true, lowest_price: "$10.00", volume: "100", median_price: "$11.00")
    end

    it "raises when the response body is unexpected" do
      stub_request(:get, "https://steamcommunity.com/market/priceoverview")
        .with(query: hash_including({}))
        .to_return(status: 200, body: {}.to_json)

      expect { described_class.price_overview("AK-47 | Redline (Field-Tested)") }
        .to raise_error(/Unexpected Steam API response/)
    end
  end
end
