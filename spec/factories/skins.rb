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

FactoryBot.define do
  factory :skin do
    sequence(:name) { |n| "Skin #{n}" }
    sequence(:object_id) { |n| "skin_object_#{n}" }
    collection_name { "Test Collection" }
    rarity { "Restricted" }
    category { "Rifles" }
    min_float { 0.0 }
    max_float { 0.7 }
    wears { [] }
    crates { [] }
    weapon { {} }
  end
end
