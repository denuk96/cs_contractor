# == Schema Information
#
# Table name: feed_items
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  details      :text
#  headline     :string           not null
#  occurred_on  :date             not null
#  signal_type  :string           not null
#  skin_item_id :integer          not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_feed_items_on_occurred_on_and_signal_type  (occurred_on,signal_type)
#  index_feed_items_on_skin_item_id                 (skin_item_id) UNIQUE
#

require "rails_helper"

RSpec.describe FeedItem, type: :model do
  describe "#signal_label" do
    it "returns a human-friendly label for known signal types" do
      feed_item = build(:feed_item, signal_type: "supply_dry_up")

      expect(feed_item.signal_label).to eq("Supply Dry Up")
    end
  end

  describe "#details" do
    it "round-trips as a hash" do
      feed_item = create(:feed_item, details: { "buy_wall_ratio" => 60.0 })

      expect(described_class.find(feed_item.id).details).to eq("buy_wall_ratio" => 60.0)
    end
  end

  describe "recent_first" do
    it "orders by occurred_on descending" do
      older = create(:feed_item, occurred_on: Date.new(2026, 1, 1))
      newer = create(:feed_item, occurred_on: Date.new(2026, 1, 15))

      expect(described_class.recent_first.map(&:id)).to eq([newer.id, older.id])
    end
  end

  describe "validations" do
    it "is invalid without skin_item" do
      feed_item = build(:feed_item, skin_item: nil)

      expect(feed_item).not_to be_valid
    end
  end
end
