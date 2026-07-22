# Pre-aggregated market totals, one row per date + skin_item flag segment.
#
# Rolling up `skin_item_histories` on every page load got slow as history grew,
# so `Market::RecalculateDailyStats` writes these rows once and the overview
# page reads them. Every stored column is additive, which is what lets a filtered
# view be answered by summing the matching segments.
class MarketDailyStat < ApplicationRecord
  SEGMENT_KEYS = %i[stattrak souvenir in_game_store].freeze

  scope :between, ->(from, to) { where(date: from..to) }
end
