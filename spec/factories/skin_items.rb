# == Schema Information
#
# Table name: skin_items
#
#  id                          :integer          not null, primary key
#  created_at                  :datetime         not null
#  last_steam_price_updated_at :datetime
#  latest_steam_order_price    :float
#  latest_steam_price          :float
#  metadata                    :text
#  name                        :string
#  rarity                      :integer
#  skin_id                     :integer
#  souvenir                    :boolean
#  stattrak                    :boolean
#  updated_at                  :datetime         not null
#  wear                        :integer
#  image                       :string
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
