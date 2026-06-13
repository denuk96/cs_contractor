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

class FeedItem < ApplicationRecord
  belongs_to :skin_item

  serialize :details, type: Hash, default: {}, coder: JSON

  enum :signal_type, {
    top_signals: "top_signals",
    supply_dry_up: "supply_dry_up",
    buy_order_increase: "buy_order_increase"
  }, validate: true

  SIGNAL_LABELS = {
    "top_signals" => "Top Signals (Pump Alert)",
    "supply_dry_up" => "Supply Dry Up",
    "buy_order_increase" => "Buy Order Increase"
  }.freeze

  scope :recent_first, -> { order(occurred_on: :desc, id: :desc) }

  def signal_label
    SIGNAL_LABELS.fetch(signal_type, signal_type.titleize)
  end
end
