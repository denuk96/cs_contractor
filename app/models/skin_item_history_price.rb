class SkinItemHistoryPrice < ApplicationRecord
  STEAM_SOURCE = "steam".freeze

  belongs_to :skin_item_history

  scope :steam, -> { where(source: STEAM_SOURCE) }
  scope :third_party, -> { where.not(source: STEAM_SOURCE) }
end