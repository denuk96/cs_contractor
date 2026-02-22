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
  CONTRACTABLE_CATEGORIES = [
    "Rifle", "Rifles",
    "SMG", "SMGs",
    "Pistol", "Pistols",
    "Shotgun", "Shotguns",
    "Sniper Rifle", "Sniper Rifles",
    "Heavy", "Heavy Equipment"
  ].freeze

  scope :contractable, -> {
    joins(:skin)
      .where.not(rarity: %w[Extraordinary Contraband])
      .where(skins: { category: CONTRACTABLE_CATEGORIES })
      .where(souvenir: false)
  }
  scope :have_prices, -> { where.not(latest_steam_price: nil) }

  def self.trending(options = {})
    SkinItems::TrendingQuery.new(options).call
  end

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

  def float_min
    if has_attribute?("skin_min_float") && !self[:skin_min_float].nil?
      self[:skin_min_float]
    else
      skin&.min_float
    end
  end

  def float_max
    if has_attribute?("skin_max_float") && !self[:skin_max_float].nil?
      self[:skin_max_float]
    else
      skin&.max_float
    end
  end

  def float_cap
    return nil if float_min.nil? || float_max.nil?

    float_max - float_min
  end

  def can_have_factory_new?
    float_min.present? && float_min < Skin::FACTORY_NEW_MAX_FLOAT
  end

  def best_possible_wear
    Skin.new(min_float: float_min).best_possible_wear
  end

  def fn_probability_percent
    Skin.fn_probability_percent(float_cap, min_float: float_min)
  end
end
