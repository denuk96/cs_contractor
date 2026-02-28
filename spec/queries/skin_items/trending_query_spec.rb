require "rails_helper"

RSpec.describe SkinItems::TrendingQuery do
  describe "#call" do
    def create_two_histories!(item)
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

    it "filters by rarity when rarity is provided as an enum key (e.g., Mid-Spec Grade)" do
      skin = create(:skin, category: "Rifle")

      mid_spec_item = create(:skin_item, skin: skin, rarity: SkinItem.rarities.fetch("Mid-Spec Grade"))
      restricted_item = create(:skin_item, skin: skin, rarity: SkinItem.rarities.fetch("Restricted"))

      create_two_histories!(mid_spec_item)
      create_two_histories!(restricted_item)

      result = described_class.new(rarity: "Mid-Spec Grade", limit: 50).call

      expect(result.map(&:id)).to include(mid_spec_item.id)
      expect(result.map(&:id)).not_to include(restricted_item.id)
    end

    it "filters by rarity when rarity is provided as an enum integer value (e.g., '2') even if only skins.rarity is populated" do
      mid_spec_skin = create(:skin, category: "Rifle", rarity: "Mid-Spec Grade")
      restricted_skin = create(:skin, category: "Rifle", rarity: "Restricted")

      mid_spec_item = create(:skin_item, skin: mid_spec_skin, rarity: nil)
      restricted_item = create(:skin_item, skin: restricted_skin, rarity: nil)

      create_two_histories!(mid_spec_item)
      create_two_histories!(restricted_item)

      result = described_class.new(rarity: "2", limit: 50).call

      expect(result.map(&:id)).to include(mid_spec_item.id)
      expect(result.map(&:id)).not_to include(restricted_item.id)
    end

    it "filters by sticker rarity string (e.g., High Grade) via skins.rarity" do
      high_grade_skin = create(:skin, category: "stickers", rarity: "High Grade")
      remarkable_skin = create(:skin, category: "stickers", rarity: "Remarkable")

      high_grade_item = create(:skin_item, skin: high_grade_skin, rarity: nil)
      remarkable_item = create(:skin_item, skin: remarkable_skin, rarity: nil)

      create_two_histories!(high_grade_item)
      create_two_histories!(remarkable_item)

      result = described_class.new(rarity: "High Grade", limit: 50).call

      expect(result.map(&:id)).to include(high_grade_item.id)
      expect(result.map(&:id)).not_to include(remarkable_item.id)
    end
  end
end
