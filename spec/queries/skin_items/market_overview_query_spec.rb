require "rails_helper"

RSpec.describe SkinItems::MarketOverviewQuery do
  # The query reads the rollup, so every example builds history and then runs
  # the recalculation the nightly job would have run.
  def rollup!(from: Date.new(2020, 1, 1), to: Date.new(2030, 1, 1))
    Market::RecalculateDailyStats.new(from: from, to: to).call
  end

  describe "#call" do
    it "aggregates every tracked item into one row per day" do
      skin = create(:skin, category: "Rifle")
      first_item = create(:skin_item, skin: skin, name: "First")
      second_item = create(:skin_item, skin: skin, name: "Second")

      create(:skin_item_history, skin_item: first_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 10, offervolume: 100, buyordervolume: 50, pricelatest: 2.0)
      create(:skin_item_history, skin_item: second_item, date: Date.new(2026, 1, 1),
                                 soldtoday: 5, offervolume: 100, buyordervolume: 150, pricelatest: 4.0)
      create(:skin_item_history, skin_item: first_item, date: Date.new(2026, 1, 2),
                                 soldtoday: 20, offervolume: 80, buyordervolume: 60, pricelatest: 3.0)
      rollup!

      result = described_class.new.call

      expect(result.days.map(&:date)).to eq([Date.new(2026, 1, 1), Date.new(2026, 1, 2)])
      expect(result.latest_date).to eq(Date.new(2026, 1, 2))

      day_one = result.days.first
      expect(day_one.items_tracked).to eq(2)
      expect(day_one.sold_volume).to eq(15)
      expect(day_one.offer_volume).to eq(200)
      expect(day_one.buy_order_volume).to eq(200)
      expect(day_one.traded_value).to eq((10 * 2.0) + (5 * 4.0))
      expect(day_one.listed_value).to eq((100 * 2.0) + (100 * 4.0))
      expect(day_one.avg_price).to eq(3.0)
      expect(day_one.turnover_rate).to eq(7.5)
      expect(day_one.buy_wall_ratio).to eq(1.0)
      expect(day_one.sold_per_item).to eq(7.5)
    end

    it "spans the entire recorded history when no range is given" do
      item = create(:skin_item)
      earliest = Date.new(2025, 1, 1)
      latest = Date.new(2026, 3, 1)

      create(:skin_item_history, skin_item: item, date: earliest,
                                 soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
      create(:skin_item_history, skin_item: item, date: latest,
                                 soldtoday: 2, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
      rollup!

      result = described_class.new.call

      expect(result.start_date).to eq(earliest)
      expect(result.end_date).to eq(latest)
      expect(result.days.map(&:date)).to eq([earliest, latest])
    end

    it "honours an explicit date range" do
      item = create(:skin_item)

      (1..5).each do |day|
        create(:skin_item_history, skin_item: item, date: Date.new(2026, 1, day),
                                   soldtoday: day, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
      end
      rollup!

      result = described_class.new(start_date: "2026-01-02", end_date: "2026-01-04").call

      expect(result.days.map(&:date)).to eq([Date.new(2026, 1, 2), Date.new(2026, 1, 3), Date.new(2026, 1, 4)])
    end

    it "excludes souvenir items by default and filters on skin item flags" do
      normal = create(:skin_item, name: "Normal", souvenir: false, stattrak: false)
      souvenir = create(:skin_item, name: "Souvenir", souvenir: true, stattrak: false)

      create(:skin_item_history, skin_item: normal, date: Date.new(2026, 1, 1),
                                 soldtoday: 10, offervolume: 100, buyordervolume: 10, pricelatest: 1.0)
      create(:skin_item_history, skin_item: souvenir, date: Date.new(2026, 1, 1),
                                 soldtoday: 7, offervolume: 100, buyordervolume: 10, pricelatest: 1.0)
      rollup!

      expect(described_class.new.call.days.first.sold_volume).to eq(10)
      expect(described_class.new(souvenir: nil).call.days.first.sold_volume).to eq(17)
      expect(described_class.new(souvenir: "true").call.days.first.sold_volume).to eq(7)
    end

    it "averages price across segments rather than averaging the averages" do
      cheap = create(:skin_item, name: "Cheap", stattrak: false)
      pricey = create(:skin_item, name: "Pricey", stattrak: true)
      priceless = create(:skin_item, name: "Unpriced", stattrak: false)

      create(:skin_item_history, skin_item: cheap, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
      create(:skin_item_history, skin_item: pricey, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: 4.0)
      # No price at all: must not drag the average toward zero.
      create(:skin_item_history, skin_item: priceless, date: Date.new(2026, 1, 1),
                                 soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: nil)
      rollup!

      expect(described_class.new(stattrak: nil).call.days.first.avg_price).to eq(2.5)
    end

    it "returns an empty result when nothing has been rolled up" do
      result = described_class.new.call

      expect(result.days).to eq([])
      expect(result.latest_date).to be_nil
    end
  end
end
