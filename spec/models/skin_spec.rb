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

require 'rails_helper'

RSpec.describe Skin, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
