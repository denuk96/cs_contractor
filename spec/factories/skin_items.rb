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

FactoryBot.define do
  factory :skin_item do
    association :skin
    sequence(:name) { |n| "Skin Item #{n}" }
    rarity { "Restricted" }
    wear { "Factory New" }
    souvenir { false }
    stattrak { false }
    latest_steam_price { 1.23 }
  end
end
