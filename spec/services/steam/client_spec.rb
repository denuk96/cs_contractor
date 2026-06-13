require "rails_helper"

RSpec.describe Steam::Client do
  subject(:client) { described_class.new(api_key: "test-key") }

  describe "#asset_prices" do
    it "returns the assets result" do
      stub_request(:get, "https://api.steampowered.com/ISteamEconomy/GetAssetPrices/v1/")
        .with(query: { key: "test-key", appid: "730", language: "english" })
        .to_return(
          status: 200,
          body: {
            result: {
              success: true,
              assets: [
                { name: "AK-47 | Redline", class: [{ name: "def_index", value: "7" }], prices: { "USD" => "123" } }
              ]
            }
          }.to_json
        )

      result = client.asset_prices

      expect(result["assets"]).to eq(
        [{ "name" => "AK-47 | Redline", "class" => [{ "name" => "def_index", "value" => "7" }], "prices" => { "USD" => "123" } }]
      )
    end
  end

  describe "error handling" do
    it "raises when the response is not successful" do
      client_without_retries = described_class.new(api_key: "test-key", retries: 0)

      stub_request(:get, "https://api.steampowered.com/ISteamEconomy/GetAssetPrices/v1/")
        .with(query: hash_including({}))
        .to_return(status: 500)

      expect { client_without_retries.asset_prices }.to raise_error(Faraday::ServerError)
    end

    it "raises when the response has no result key" do
      stub_request(:get, "https://api.steampowered.com/ISteamEconomy/GetAssetPrices/v1/")
        .with(query: hash_including({}))
        .to_return(status: 200, body: {}.to_json)

      expect { client.asset_prices }.to raise_error(/Unexpected Steam API response/)
    end
  end
end
