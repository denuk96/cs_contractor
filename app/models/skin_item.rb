# == Schema Information
#
# Table name: skin_items
#
#  id                          :integer          not null, primary key
#  name                        :string
#  rarity                      :integer
#  wear                        :integer
#  souvenir                    :boolean
#  stattrak                    :boolean
#  latest_steam_price          :float
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  skin_id                     :integer
#  last_steam_price_updated_at :datetime
#  metadata                    :text
#  latest_steam_order_price    :float
#
# Indexes
#
#  index_skin_items_on_name     (name) UNIQUE
#  index_skin_items_on_skin_id  (skin_id)
#

class SkinItem < ApplicationRecord
  belongs_to :skin
  has_many :skin_item_histories, dependent: :destroy

  serialize :metadata, type: Hash, default: {}, coder: JSON

  enum :rarity, {
    "Consumer Grade" => 0,
    "Industrial Grade" => 1,
    "Mid-Spec Grade" => 2,
    "Restricted" => 3,
    "Classified" => 4,
    "Covert" => 5,
    "Extraordinary" => 6,
    "Contraband" => 7
  }

  enum :wear, {
    "Factory New" => 0,
    "Minimal Wear" => 1,
    "Field-Tested" => 2,
    "Well-Worn" => 3,
    "Battle-Scarred" => 4
  }

  scope :not_souvenir, -> { where(souvenir: false) }
  scope :contractable, -> {
    joins(:skin)
      .where.not(rarity: %w[Extraordinary Contraband])
         .where(skins: { category: %w[Rifles SMGs Pistols Heavy Equipment] })
         .where(souvenir: false)
  }
  scope :have_prices, -> { where.not(latest_steam_price: nil) }

  def update_latest_price
    result = SteamApi.price_overview(name, timeout: 10, open_timeout: 5)
    unless result[:success]
      Rails.logger.warn "Failed to get price for #{name}: #{result.inspect}"
      return false
    end

    return false if result[:lowest_price].nil?

    Rails.logger.info "Updating price for #{name}: #{result.inspect}"
    update(latest_steam_price: result[:lowest_price].delete("$").to_f, last_steam_price_updated_at: Time.zone.now)
  end

  def fetch_order_activity
    SteamWebApi.new.orders_activity(name)
  end
end
