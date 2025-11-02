require "rails_helper"

# rubocop:disable RSpec/ ExampleLength
RSpec.describe Tradeups::FindProfitableContracts do
  let(:tradeup) do
    Tradeups::FindProfitableContracts.new(
      from_rarity: "Mid-Spec Grade",
      price_fee_multiplier: 0.85,
      min_profit: 0.0
    )
  end

  before do
    ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("spec/fixtures/inferno_2018"), "skin_items")
  end

  context "when contracts are found" do
    it "returns a list of contracts" do
      contracts = tradeup.call
      minimum_outcome = SkinItem.find_by(name: "P250 | Vino Primo")
      maximum_outcome = SkinItem.find_by(name: "MP7 | Fade")
      expect(contracts.size).to eq(1)
      expect(contracts.first.stack.first[:item].name).to eq("Sawed-Off | Brake Light")
      expect(contracts.first.cost).to eq(0.5)
      expect(contracts.first.minimal_expected_value).to eq(minimum_outcome.latest_steam_price * 0.85)
      expect(contracts.first.maximum_expected_value).to eq(maximum_outcome.latest_steam_price * 0.85)
    end
  end
end
# rubocop:enable RSpec/ ExampleLength
