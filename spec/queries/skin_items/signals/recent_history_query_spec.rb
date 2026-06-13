require "rails_helper"

RSpec.describe SkinItems::Signals::RecentHistoryQuery do
  describe "#call" do
    it "groups histories from the last 14 days by skin_item_id, oldest first" do
      skin = create(:skin, category: "Rifle")
      item = create(:skin_item, skin: skin, name: "Item")

      old = create(:skin_item_history, skin_item: item, date: Date.current - 20.days,
                                       soldtoday: 1, buyordervolume: 1, offervolume: 1,
                                       pricelatest: 10.0, buyorderprice: 9.0)
      recent_old = create(:skin_item_history, skin_item: item, date: Date.current - 5.days,
                                              soldtoday: 2, buyordervolume: 2, offervolume: 2,
                                              pricelatest: 10.0, buyorderprice: 9.0)
      recent_new = create(:skin_item_history, skin_item: item, date: Date.current,
                                              soldtoday: 3, buyordervolume: 3, offervolume: 3,
                                              pricelatest: 10.0, buyorderprice: 9.0)

      result = described_class.new([item.id]).call

      expect(result[item.id]).to eq([recent_old, recent_new])
      expect(result[item.id]).not_to include(old)
    end
  end
end
