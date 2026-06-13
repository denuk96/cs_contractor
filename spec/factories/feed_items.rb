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

FactoryBot.define do
  factory :feed_item do
    association :skin_item
    signal_type { "top_signals" }
    occurred_on { Date.current }
    headline { "Pump alert: buy wall at 60.0x offer volume with 20.0% daily turnover" }
    details { { buy_wall_ratio: 60.0, turnover_pct: 20.0 } }
  end
end
