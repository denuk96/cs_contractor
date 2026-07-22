require "rails_helper"

RSpec.describe BackfillMarketDailyStatsJob do
  let(:item) { create(:skin_item) }

  def history_on(date, sold: 1)
    create(:skin_item_history, skin_item: item, date: date,
                               soldtoday: sold, offervolume: 10, buyordervolume: 1, pricelatest: 1.0)
  end

  def enqueued_dates
    enqueued_jobs.select { |job| job[:job] == RecalculateMarketDayJob }.flat_map { |job| job[:args] }
  end

  it "enqueues one day job per date from the given start through the latest history" do
    history_on(Date.new(2026, 1, 1))
    history_on(Date.new(2026, 1, 4))

    described_class.perform_now("2025-12-25")

    expect(enqueued_dates).to eq(%w[2026-01-01 2026-01-02 2026-01-03 2026-01-04])
  end

  it "clamps the start date up to the earliest recorded history" do
    history_on(Date.new(2026, 6, 1))

    described_class.perform_now(described_class::HISTORY_START.to_s)

    expect(enqueued_dates).to eq(["2026-06-01"])
  end

  it "accepts an explicit end date" do
    history_on(Date.new(2026, 1, 1))
    history_on(Date.new(2026, 3, 1))

    described_class.perform_now("2026-01-01", "2026-01-02")

    expect(enqueued_dates).to eq(%w[2026-01-01 2026-01-02])
  end

  it "enqueues nothing when there is no history to roll up" do
    described_class.perform_now

    expect(enqueued_dates).to be_empty
  end

  it "rebuilds the range once the enqueued day jobs run" do
    history_on(Date.new(2026, 1, 1), sold: 2)
    history_on(Date.new(2026, 1, 3), sold: 5)

    perform_enqueued_jobs { described_class.perform_now("2026-01-01") }

    expect(MarketDailyStat.pluck(:date)).to match_array([Date.new(2026, 1, 1), Date.new(2026, 1, 3)])
    expect(MarketDailyStat.sum(:sold_volume)).to eq(7)
  end
end
