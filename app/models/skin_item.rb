# == Schema Information
#
# Table name: skin_items
#
#  id                 :integer          not null, primary key
#  name               :string
#  object_id          :string
#  rarity             :integer
#  wear               :integer
#  collection_name    :string
#  souvenir           :boolean
#  stattrak           :boolean
#  category           :string
#  min_float          :float
#  max_float          :float
#  latest_steam_price :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class SkinItem < ApplicationRecord
  enum :rarity, {
    "Consumer Grade" => 0,
    "Industrial Grade" => 1,
    "Mid-Spec Grade" => 2,
    "Restricted" => 3,
    "Classified" => 4,
    "Covert" => 5
  }

  enum :wear, {
    "Factory New" => 0,
    "Minimal Wear" => 1,
    "Field-Tested" => 2,
    "Well-Worn" => 3,
    "Battle-Scarred" => 4
  }

  scope :not_souvenir, -> { where(souvenir: false) }
end
