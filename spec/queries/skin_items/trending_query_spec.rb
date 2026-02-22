require "rails_helper"

RSpec.describe SkinItems::TrendingQuery do
  describe "#call" do
    it "returns items ordered by soldtoday delta by default" do
      skin = create(:skin, category: "Rifle", crates: ["Inferno Collection"])

      item_a = create(:skin_item, skin: skin, name: "A")
      item_b = create(:skin_item, skin: skin, name: "B")

      create(
        :skin_item_history,
        skin_item: item_a,
        date: Date.new(2026, 1, 1),
        soldtoday: 1,
        buyordervolume: 10,
        offervolume: 100,
        pricelatest: 1.0,
        buyorderprice: 0.9
      )
      create(
        :skin_item_history,
        skin_item: item_a,
        date: Date.new(2026, 2, 1),
        soldtoday: 20,
        buyordervolume: 20,
        offervolume: 90,
        pricelatest: 1.1,
        buyorderprice: 1.0
      )

      create(
        :skin_item_history,
        skin_item: item_b,
        date: Date.new(2026, 1, 1),
        soldtoday: 5,
        buyordervolume: 10,
        offervolume: 100,
        pricelatest: 1.0,
        buyorderprice: 0.9
      )
      create(
        :skin_item_history,
        skin_item: item_b,
        date: Date.new(2026, 2, 1),
        soldtoday: 10,
        buyordervolume: 20,
        offervolume: 90,
        pricelatest: 1.1,
        buyorderprice: 1.0
      )

      result = described_class.new(limit: 10).call

      expect(result.map(&:id)).to include(item_a.id, item_b.id)
      expect(result.map(&:id).index(item_a.id)).to be < result.map(&:id).index(item_b.id)
    end

    it "filters by category" do
      rifle_skin = create(:skin, category: "Rifle")
      pistol_skin = create(:skin, category: "Pistol")

      rifle_item = create(:skin_item, skin: rifle_skin)
      pistol_item = create(:skin_item, skin: pistol_skin)

      [rifle_item, pistol_item].each do |item|
        create(
          :skin_item_history,
          skin_item: item,
          date: Date.new(2026, 1, 1),
          soldtoday: 1,
          buyordervolume: 1,
          offervolume: 10,
          pricelatest: 1.0,
          buyorderprice: 0.9
        )
        create(
          :skin_item_history,
          skin_item: item,
          date: Date.new(2026, 2, 1),
          soldtoday: 2,
          buyordervolume: 2,
          offervolume: 9,
          pricelatest: 1.1,
          buyorderprice: 1.0
        )
      end

      result = described_class.new(category: "Rifle", limit: 50).call

      expect(result.map(&:id)).to include(rifle_item.id)
      expect(result.map(&:id)).not_to include(pistol_item.id)
    end
  end
end
