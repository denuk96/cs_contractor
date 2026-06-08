class SkinItemHistoryPrice < ApplicationRecord
  STEAM_SOURCE = "steam".freeze
  # Feeds occasionally return junk quotes (e.g. billions); cap at a sane ceiling.
  MAX_PRICE = 100_000

  belongs_to :skin_item_history

  validates :price,
            numericality: { greater_than: 0, less_than_or_equal_to: MAX_PRICE },
            allow_nil: true

  scope :steam, -> { where(source: STEAM_SOURCE) }
  scope :third_party, -> { where.not(source: STEAM_SOURCE) }
  # Only quotes within the sane range — bulk upserts skip validation, so the
  # read side must defend against the junk that slips into the table.
  scope :priced, -> { where("skin_item_history_prices.price > 0 AND skin_item_history_prices.price <= ?", MAX_PRICE) }
end