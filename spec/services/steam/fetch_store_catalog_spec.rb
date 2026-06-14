require "rails_helper"

RSpec.describe Steam::FetchStoreCatalog do
  subject(:catalog) { described_class.new(client: client).call }

  let(:client) { instance_double(Steam::Client) }
  let(:assets) do
    {
      "assets" => [
        { "classid" => "100", "prices" => { "USD" => 1050 }, "original_prices" => { "USD" => 1500 } },
        { "classid" => "200", "prices" => { "USD" => 250 } }
      ]
    }
  end
  let(:class_info) do
    {
      "100" => {
        "name" => "AK-47 | Redline",
        "market_hash_name" => "AK-47 | Redline (Field-Tested)",
        "icon_url" => "ak47_redline_icon"
      },
      "200" => {
        "name" => "M4A4 | Asiimov",
        "market_hash_name" => "M4A4 | Asiimov (Field-Tested)",
        "icon_url" => "m4a4_asiimov_icon"
      }
    }
  end

  before do
    allow(client).to receive(:asset_prices).and_return(assets)
    allow(client).to receive(:asset_class_info).with(%w[100 200]).and_return(class_info)
  end

  it "merges Valve's asset prices with the official class info" do
    expect(catalog).to contain_exactly(
      {
        "classid" => "100",
        "name" => "AK-47 | Redline",
        "market_hash_name" => "AK-47 | Redline (Field-Tested)",
        "icon_url" => "https://community.cloudflare.steamstatic.com/economy/image/ak47_redline_icon",
        "price_usd" => 10.5,
        "original_price_usd" => 15.0
      },
      {
        "classid" => "200",
        "name" => "M4A4 | Asiimov",
        "market_hash_name" => "M4A4 | Asiimov (Field-Tested)",
        "icon_url" => "https://community.cloudflare.steamstatic.com/economy/image/m4a4_asiimov_icon",
        "price_usd" => 2.5,
        "original_price_usd" => nil
      }
    )
  end

  context "when there are no assets currently for sale" do
    let(:assets) { { "assets" => [] } }

    it "returns an empty catalog without requesting class info" do
      expect(catalog).to be_empty
      expect(client).not_to have_received(:asset_class_info)
    end
  end

  context "when class info is missing for a classid" do
    let(:class_info) { super().except("200") }

    it "excludes that asset from the catalog" do
      expect(catalog.map { |item| item["classid"] }).to contain_exactly("100")
    end
  end

  context "when there are more than the batch size of assets" do
    let(:assets) do
      { "assets" => (1..60).map { |i| { "classid" => i.to_s, "prices" => { "USD" => 100 } } } }
    end

    it "queries class info in batches" do
      first_batch = (1..50).map(&:to_s)
      second_batch = (51..60).map(&:to_s)

      allow(client).to receive(:asset_class_info).with(first_batch).and_return(
        first_batch.to_h { |id| [id, { "name" => "Item #{id}", "market_hash_name" => "Item #{id}", "icon_url" => "" }] }
      )
      allow(client).to receive(:asset_class_info).with(second_batch).and_return(
        second_batch.to_h { |id| [id, { "name" => "Item #{id}", "market_hash_name" => "Item #{id}", "icon_url" => "" }] }
      )

      expect(catalog.size).to eq(60)
      expect(client).to have_received(:asset_class_info).with(first_batch)
      expect(client).to have_received(:asset_class_info).with(second_batch)
    end
  end
end
