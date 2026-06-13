require "rails_helper"

RSpec.describe Feed::ChartSeries do
  describe "#call" do
    it "plots the buy wall ratio for a top_signals entry" do
      feed_item = build(:feed_item, signal_type: "top_signals")
      history = build_stubbed(:skin_item_history, date: Date.current, buyordervolume: 60, offervolume: 10)

      series = described_class.new(feed_item, [history]).call

      expect(series).to eq([{ name: "Buy wall ratio", data: [[Date.current, 6.0]] }])
    end

    it "plots the turnover percentage for a supply_dry_up entry" do
      feed_item = build(:feed_item, signal_type: "supply_dry_up")
      history = build_stubbed(:skin_item_history, date: Date.current, soldtoday: 3, offervolume: 10)

      series = described_class.new(feed_item, [history]).call

      expect(series).to eq([{ name: "Turnover %", data: [[Date.current, 30.0]] }])
    end

    it "plots the buy order volume for a buy_order_increase entry" do
      feed_item = build(:feed_item, signal_type: "buy_order_increase")
      history = build_stubbed(:skin_item_history, date: Date.current, buyordervolume: 15)

      series = described_class.new(feed_item, [history]).call

      expect(series).to eq([{ name: "Buy order volume", data: [[Date.current, 15.0]] }])
    end

    it "treats a zero denominator as a zero ratio" do
      feed_item = build(:feed_item, signal_type: "supply_dry_up")
      history = build_stubbed(:skin_item_history, date: Date.current, soldtoday: 3, offervolume: 0)

      series = described_class.new(feed_item, [history]).call

      expect(series).to eq([{ name: "Turnover %", data: [[Date.current, 0.0]] }])
    end
  end
end
