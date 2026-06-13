require "rails_helper"

RSpec.describe SkinItems::Signals::SupplyDryUpQuery do
  describe "#call" do
    it "returns items whose latest turnover is at or above the squeeze threshold" do
      skin = create(:skin, category: "Rifle")
      squeezed_item = create(:skin_item, skin: skin, name: "Squeezed")
      calm_item = create(:skin_item, skin: skin, name: "Calm")

      create(:skin_item_history, skin_item: squeezed_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 5, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: squeezed_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 3, buyordervolume: 5, offervolume: 10,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      create(:skin_item_history, skin_item: calm_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 5, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: calm_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 1, buyordervolume: 5, offervolume: 10,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      result = described_class.new.call

      expect(result.map(&:id)).to include(squeezed_item.id)
      expect(result.map(&:id)).not_to include(calm_item.id)
    end
  end

  describe ".headline and .details" do
    it "describe the turnover rate" do
      # current_* attributes come from the find_by_sql projection, not SkinItem
      # itself, so instance_double can't verify them.
      item = double(current_soldtoday: 3, current_offervolume: 10, current_price: 10.0) # rubocop:disable RSpec/VerifiedDoubles

      expect(described_class.headline(item)).to eq(
        "Supply drying up: 30.0% turnover (3 sold of 10 listed today)"
      )
      expect(described_class.details(item)).to eq(
        turnover_pct: 30.0,
        sold_today: 3,
        offer_volume: 10,
        latest_price: 10.0
      )
    end
  end
end
