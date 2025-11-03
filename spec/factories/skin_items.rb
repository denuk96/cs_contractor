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

FactoryBot.define do
  factory :skin_item do

  end
end
