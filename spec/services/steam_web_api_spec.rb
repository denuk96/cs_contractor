require "rails_helper"

RSpec.describe SteamWebApi do
  subject(:api) { described_class.new }

  before do
    @orig_key = ENV["STEAM_WEB_API_KEY"]
    ENV["STEAM_WEB_API_KEY"] = "test-key"
  end

  after { ENV["STEAM_WEB_API_KEY"] = @orig_key }

  describe "#each_item" do
    def stub_items(body:, status: 200)
      stub_request(:get, "#{described_class::BASE_URL}/items")
        .with(query: hash_including("key" => "test-key", "format" => "ndjson", "game" => "cs2"))
        .to_return(status: status, body: body)
    end

    def ndjson(*rows)
      rows.map(&:to_json).join("\n") << "\n"
    end

    it "yields each ndjson line as a parsed hash" do
      stub_items(body: ndjson(
        { "markethashname" => "AK-47 | Redline (Field-Tested)", "pricelatest" => 12.3 },
        { "markethashname" => "M4A4 | Asiimov (Field-Tested)", "pricelatest" => 45.6 }
      ))

      items = api.each_item(game: "cs2").to_a

      expect(items.map { |i| i["markethashname"] }).to eq(
        ["AK-47 | Redline (Field-Tested)", "M4A4 | Asiimov (Field-Tested)"]
      )
      expect(items.last["pricelatest"]).to eq(45.6)
    end

    it "preserves non-ASCII names (StatTrak™, é) across the streamed read" do
      stub_items(body: ndjson({ "markethashname" => "StatTrak™ AK-47 | Redline" }))

      expect(api.each_item(game: "cs2").to_a.first["markethashname"])
        .to eq("StatTrak™ AK-47 | Redline")
    end

    it "skips blank lines" do
      stub_items(body: "\n#{{ 'markethashname' => 'Glock-18 | Fade' }.to_json}\n\n")

      expect(api.each_item(game: "cs2").to_a.size).to eq(1)
    end

    it "raises when the server ignores format=ndjson and returns a JSON array" do
      stub_items(body: [{ "markethashname" => "x" }].to_json)

      expect { api.each_item(game: "cs2") { |_| } }
        .to raise_error(/returned a JSON array/)
    end

    it "raises on a non-success response" do
      stub_items(body: "boom", status: 500)

      expect { api.each_item(game: "cs2") { |_| } }.to raise_error(/HTTP 500/)
    end

    it "raises on an empty/truncated body instead of silently importing nothing" do
      stub_items(body: "")

      expect { api.each_item(game: "cs2") { |_| } }.to raise_error(/produced no items/)
    end
  end
end
