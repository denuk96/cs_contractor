require "rails_helper"

RSpec.describe Market::RecalculateDailyStats do
  let(:date) { Date.new(2026, 1, 10) }

  it "writes one row per date and skin item flag segment" do
    normal = create(:skin_item, name: "Normal", stattrak: false, souvenir: false, in_game_store: false)
    stattrak = create(:skin_item, name: "StatTrak", stattrak: true, souvenir: false, in_game_store: true)

    create(:skin_item_history, skin_item: normal, date: date,
                               soldtoday: 3, offervolume: 30, buyordervolume: 12, pricelatest: 2.0)
    create(:skin_item_history, skin_item: stattrak, date: date,
                               soldtoday: 1, offervolume: 10, buyordervolume: 5, pricelatest: 8.0)

    result = described_class.new(from: date, to: date).call

    expect(result.rows_written).to eq(2)
    expect(MarketDailyStat.count).to eq(2)

    normal_row = MarketDailyStat.find_by(date: date, stattrak: false)
    expect(normal_row).to have_attributes(
      souvenir: false, in_game_store: false, items_tracked: 1,
      sold_volume: 3, offer_volume: 30, buy_order_volume: 12,
      traded_value: 6.0, listed_value: 60.0, price_sum: 2.0, priced_items: 1
    )

    stattrak_row = MarketDailyStat.find_by(date: date, stattrak: true)
    expect(stattrak_row).to have_attributes(in_game_store: true, sold_volume: 1, listed_value: 80.0)
  end

  it "is idempotent — re-running replaces the range instead of duplicating it" do
    item = create(:skin_item)
    create(:skin_item_history, skin_item: item, date: date,
                               soldtoday: 5, offervolume: 50, buyordervolume: 5, pricelatest: 1.0)

    2.times { described_class.new(from: date, to: date).call }

    expect(MarketDailyStat.where(date: date).count).to eq(1)
    expect(MarketDailyStat.find_by(date: date).sold_volume).to eq(5)
  end

  it "picks up corrected history on a re-run" do
    item = create(:skin_item)
    history = create(:skin_item_history, skin_item: item, date: date,
                                         soldtoday: 5, offervolume: 50, buyordervolume: 5, pricelatest: 1.0)
    described_class.new(from: date, to: date).call

    history.update!(soldtoday: 40)
    described_class.new(from: date, to: date).call

    expect(MarketDailyStat.find_by(date: date).sold_volume).to eq(40)
  end

  it "clears days inside the range that no longer have history" do
    item = create(:skin_item)
    history = create(:skin_item_history, skin_item: item, date: date,
                                         soldtoday: 5, offervolume: 50, buyordervolume: 5, pricelatest: 1.0)
    described_class.new(from: date, to: date).call

    history.destroy!
    described_class.new(from: date, to: date).call

    expect(MarketDailyStat.where(date: date)).to be_empty
  end

  it "only touches the requested range" do
    item = create(:skin_item)
    create(:skin_item_history, skin_item: item, date: date - 5,
                               soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
    create(:skin_item_history, skin_item: item, date: date,
                               soldtoday: 2, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
    described_class.new(from: date - 5, to: date).call

    described_class.new(from: date, to: date).call

    expect(MarketDailyStat.pluck(:date)).to match_array([date - 5, date])
  end

  it "spans batches larger than BATCH_DAYS" do
    item = create(:skin_item)
    from = date
    to = date + described_class::BATCH_DAYS + 5

    [from, from + described_class::BATCH_DAYS, to].each do |day|
      create(:skin_item_history, skin_item: item, date: day,
                                 soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
    end

    result = described_class.new(from: from, to: to).call

    expect(result.rows_written).to eq(3)
    expect(MarketDailyStat.pluck(:date)).to match_array([from, from + described_class::BATCH_DAYS, to])
  end
end
