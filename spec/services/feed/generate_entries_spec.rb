require "rails_helper"

RSpec.describe Feed::GenerateEntries do
  describe "#call" do
    it "creates a single feed item for the highest-priority matching signal" do
      skin = create(:skin, category: "Rifle")
      item = create(:skin_item, skin: skin, name: "Pumped")

      # This history also satisfies BuyOrderIncreaseQuery (10 -> 600 buy
      # order volume), so it matches two signals at once.
      create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 10, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, 15),
                                 soldtoday: 2, buyordervolume: 600, offervolume: 10,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      expect { described_class.new.call }.to change(FeedItem, :count).from(0).to(1)

      feed_item = FeedItem.find_by(skin_item: item)
      expect(feed_item.signal_type).to eq("top_signals")
      expect(feed_item.occurred_on).to eq(Date.new(2026, 1, 15))
      expect(feed_item.headline).to include("Pump alert")
      expect(feed_item.details["buy_wall_ratio"]).to eq(60.0)
    end

    it "is idempotent: re-running refreshes the existing entry instead of duplicating it" do
      skin = create(:skin, category: "Rifle")
      item = create(:skin_item, skin: skin, name: "Pumped")

      create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 10, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, 15),
                                 soldtoday: 2, buyordervolume: 600, offervolume: 10,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      described_class.new.call

      expect { described_class.new.call }.not_to change(FeedItem, :count)
    end

    it "does nothing when no item matches any signal" do
      skin = create(:skin, category: "Rifle")
      item = create(:skin_item, skin: skin, name: "Quiet")

      create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, buyordervolume: 5, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)
      create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, 15),
                                 soldtoday: 1, buyordervolume: 5, offervolume: 100,
                                 pricelatest: 10.0, buyorderprice: 9.0)

      expect { described_class.new.call }.not_to change(FeedItem, :count)
    end
  end
end
