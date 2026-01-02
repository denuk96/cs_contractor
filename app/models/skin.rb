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

  {
    "Factory New" => 0.07,
    "Minimal Wear" => 0.07..0.15,
    "Field-Tested" => 0.15..0.38,
    "Well-Worn" => 0.38..0.45,
    "Battle-Scarred" => 0.45..1.0
  }
end
