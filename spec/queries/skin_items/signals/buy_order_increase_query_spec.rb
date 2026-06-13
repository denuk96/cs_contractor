require "rails_helper"

RSpec.describe SkinItems::Signals::BuyOrderIncreaseQuery do
  describe "#call" do
    it "returns items whose buy order volume rose meaningfully since the first snapshot" do
      skin = create(:skin, category: "Rifle")
      accumulating_item = create(:skin_item, skin: skin, name: "Accumulating")
      flat_item = create(:skin_item, skin: skin, name: "Flat")
      thin_item = create(:skin_item, skin: skin, name: "Thin")

      create(:skin_item_history, skin_item: accumulating_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 10, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: accumulating_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 1, buyordervolume: 15, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      create(:skin_item_history, skin_item: flat_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 10, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: flat_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 1, buyordervolume: 11, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      # Below the minimum previous buy order volume, even though the ratio is huge.
      create(:skin_item_history, skin_item: thin_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 1, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: thin_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 1, buyordervolume: 5, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      result = described_class.new.call

      expect(result.map(&:id)).to include(accumulating_item.id)
      expect(result.map(&:id)).not_to include(flat_item.id)
      expect(result.map(&:id)).not_to include(thin_item.id)
    end
  end

  describe ".headline and .details" do
    it "describe the increase in buy order volume" do
      # current_* / prev_* attributes come from the find_by_sql projection, not
      # SkinItem itself, so instance_double can't verify them.
      item = double(current_buyordervolume: 15, prev_buyordervolume: 10, current_price: 10.0) # rubocop:disable RSpec/VerifiedDoubles

      expect(described_class.headline(item)).to eq("Buy orders rose from 10 to 15 (+50.0%)")
      expect(described_class.details(item)).to eq(
        buy_order_volume: 15,
        prev_buy_order_volume: 10,
        increase_pct: 50.0,
        latest_price: 10.0
      )
    end
  end
end
