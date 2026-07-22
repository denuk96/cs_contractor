require "rails_helper"

RSpec.describe RecalculateMarketDayJob do
  let(:date) { Date.new(2026, 1, 10) }

  it "rebuilds only the given day" do
    item = create(:skin_item)
    create(:skin_item_history, skin_item: item, date: date,
                               soldtoday: 4, offervolume: 40, buyordervolume: 8, pricelatest: 2.0)
    create(:skin_item_history, skin_item: item, date: date + 1,
                               soldtoday: 9, offervolume: 40, buyordervolume: 8, pricelatest: 2.0)

    described_class.perform_now(date.to_s)

    expect(MarketDailyStat.pluck(:date)).to eq([date])
    expect(MarketDailyStat.find_by(date: date)).to have_attributes(sold_volume: 4, offer_volume: 40)
  end

  it "accepts a Date as well as an ISO string" do
    item = create(:skin_item)
    create(:skin_item_history, skin_item: item, date: date,
                               soldtoday: 1, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)

    described_class.perform_now(date)

    expect(MarketDailyStat.find_by(date: date).sold_volume).to eq(1)
  end
end
