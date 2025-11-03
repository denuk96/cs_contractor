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

FactoryBot.define do
  factory :skin_item do

  end
end
