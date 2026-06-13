require "rails_helper"

RSpec.describe Feed::PruneStaleEntries do
  describe "#call" do
    it "removes feed items whose signal occurred more than 7 days ago" do
      stale = create(:feed_item, occurred_on: Date.current - 8.days)
      fresh = create(:feed_item, occurred_on: Date.current - 6.days)

      described_class.new.call

      expect(FeedItem.exists?(stale.id)).to be(false)
      expect(FeedItem.exists?(fresh.id)).to be(true)
    end

    it "keeps a feed item dated exactly at the retention boundary" do
      boundary = create(:feed_item, occurred_on: Date.current - 7.days)

      described_class.new.call

      expect(FeedItem.exists?(boundary.id)).to be(true)
    end
  end
end
