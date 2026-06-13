require "rails_helper"

RSpec.describe Steam::FetchStoreCatalog do
  subject(:catalog) { described_class.new(client: client).call }

  let(:client) { instance_double(Steam::Client) }
  let(:assets) do
    {
      "assets" => [
        { "name" => "AK-47 | Redline", "class" => [{ "name" => "def_index", "value" => "7" }] },
        { "name" => "M4A4 | Asiimov", "class" => [{ "name" => "def_index", "value" => "9" }] }
      ]
    }
  end
  let(:all_items) do
    {
      "ak47_redline" => { "def_index" => 7, "market_hash_name" => "AK-47 | Redline (Field-Tested)" },
      "m4a4_asiimov" => { "def_index" => 9, "market_hash_name" => "M4A4 | Asiimov (Field-Tested)" },
      "awp_dragon_lore" => { "def_index" => 16, "market_hash_name" => "AWP | Dragon Lore (Factory New)" }
    }
  end

  before do
    allow(client).to receive(:asset_prices).and_return(assets)
    stub_request(:get, Steam::FetchStoreCatalog::ALL_ITEMS_URL).to_return(status: 200, body: all_items.to_json)
  end

  it "returns only items whose def_index is currently sold in the store" do
    expect(catalog.map { |item| item["market_hash_name"] })
      .to contain_exactly("AK-47 | Redline (Field-Tested)", "M4A4 | Asiimov (Field-Tested)")
  end

  context "when an asset has no def_index" do
    let(:assets) do
      { "assets" => [{ "name" => "Sticker | Some Sticker", "class" => [{ "name" => "color", "value" => "abc" }] }] }
    end

    it "matches nothing" do
      expect(catalog).to be_empty
    end
  end
end
