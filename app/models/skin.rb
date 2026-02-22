# == Schema Information
#
# Table name: skins
#
#  id              :integer          not null, primary key
#  name            :string
#  object_id       :string
#  collection_name :string
#  rarity          :string
#  souvenir        :boolean
#  stattrak        :boolean
#  category        :string
#  min_float       :float
#  max_float       :float
#  wears           :text
#  crates          :text
#  weapon          :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_skins_on_name       (name) UNIQUE
#  index_skins_on_object_id  (object_id) UNIQUE
#

class Skin < ApplicationRecord
  ITEM_TYPES = %w[skins stickers keychains crates collectibles agents patches graffiti music_kits highlights].freeze
  serialize :wears, type: Array, default: [], coder: JSON
  serialize :crates, type: Array, default: [], coder: JSON
  serialize :weapon, type: Hash, default: {}, coder: JSON

  has_many :skin_items, dependent: :destroy

  FACTORY_NEW_MAX_FLOAT = 0.07
  FLOAT_RANGE_DECAY_START = 0.7
  FLOAT_RANGE_DECAY_K = 10.49

  WEAR_RANGES = {
    "Factory New" => (0.0..0.07),
    "Minimal Wear" => (0.07..0.15),
    "Field-Tested" => (0.15..0.38),
    "Well-Worn" => (0.38..0.45),
    "Battle-Scarred" => (0.45..1.0)
  }.freeze

  def float_cap
    return nil if min_float.nil? || max_float.nil?

    max_float - min_float
  end

  def can_have_factory_new?
    return false if min_float.nil?

    min_float < FACTORY_NEW_MAX_FLOAT
  end

  def best_possible_wear
    return nil if min_float.nil?

    if min_float < 0.07
      "Factory New"
    elsif min_float < 0.15
      "Minimal Wear"
    elsif min_float < 0.38
      "Field-Tested"
    elsif min_float < 0.45
      "Well-Worn"
    else
      "Battle-Scarred"
    end
  end

  def fn_probability_percent
    self.class.fn_probability_percent(float_cap, min_float: min_float)
  end

  def self.fn_probability_percent(float_range, min_float:)
    return nil if float_range.nil?
    return 0.0 if min_float.nil? || min_float >= FACTORY_NEW_MAX_FLOAT

    range = float_range.to_f
    if range <= 0.0
      return 100.0 if min_float < FACTORY_NEW_MAX_FLOAT

      return 0.0
    end

    y = FACTORY_NEW_MAX_FLOAT / range
    if range > FLOAT_RANGE_DECAY_START
      y *= Math.exp(-FLOAT_RANGE_DECAY_K * (range - FLOAT_RANGE_DECAY_START))
    end

    percent = y * 100
    return 0.0 if percent.nan? || percent.infinite? || percent.negative?

    [percent, 100.0].min
  end
end
