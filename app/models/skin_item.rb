# == Schema Information
#
# Table name: skin_items
#
#  id                 :integer          not null, primary key
#  name               :string
#  rarity             :integer
#  wear               :integer
#  souvenir           :boolean
#  stattrak           :boolean
#  latest_steam_price :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  skin_id            :integer
#
# Indexes
#
#  index_skin_items_on_name     (name) UNIQUE
#  index_skin_items_on_skin_id  (skin_id)
#

class SkinItem < ApplicationRecord
  belongs_to :skin

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
         .where.not(skins: { category: %w[Gloves Knives] })
         .where(souvenir: false)
  }
end
