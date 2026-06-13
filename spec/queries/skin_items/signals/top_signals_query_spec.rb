require "rails_helper"

RSpec.describe SkinItems::Signals::TopSignalsQuery do
  describe "#call" do
    it "returns items with a buy wall, high turnover, shrinking supply and a near-ask buy order" do
      skin = create(:skin, category: "Rifle")
      pumped_item = create(:skin_item, skin: skin, name: "Pumped")
      quiet_item = create(:skin_item, skin: skin, name: "Quiet")

      # 14 days before the latest snapshot, satisfying the >=10 day comparison window.
      create(:skin_item_history, skin_item: pumped_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 10, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: pumped_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 2, buyordervolume: 600, offervolume: 10,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      create(:skin_item_history, skin_item: quiet_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 10, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: quiet_item, date: Date.new(2026, 1, 15),
                                 soldtoday: 2, buyordervolume: 12, offervolume: 90,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      result = described_class.new.call

      expect(result.map(&:id)).to include(pumped_item.id)
      expect(result.map(&:id)).not_to include(quiet_item.id)
    end
  end

  describe ".headline and .details" do
    it "describe the buy wall ratio and turnover" do
      # current_* / prev_* attributes come from the find_by_sql projection, not
      # SkinItem itself, so instance_double can't verify them.
      item = double( # rubocop:disable RSpec/VerifiedDoubles
        current_buyordervolume: 600,
        current_offervolume: 10,
        current_soldtoday: 2,
        current_buyorderprice: 9.0,
        current_price: 10.0,
        prev_offervolume: 100
      )

      expect(described_class.headline(item)).to eq(
        "Pump alert: buy wall at 60.0x offer volume with 20.0% daily turnover"
      )
      expect(described_class.details(item)).to eq(
        buy_wall_ratio: 60.0,
        turnover_pct: 20.0,
        buy_order_price: 9.0,
        latest_price: 10.0,
        offer_volume: 10,
        prev_offer_volume: 100
      )
    end
  end
end
