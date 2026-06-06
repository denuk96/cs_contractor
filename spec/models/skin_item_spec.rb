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

require "rails_helper"

RSpec.describe SkinItem, type: :model do
  describe "float data derived from joined skin" do
    it "uses joined skin_min_float/skin_max_float aliases when present" do
      skin_item = create(:skin_item, skin: create(:skin, min_float: 0.0, max_float: 0.7))

      joined = SkinItem.joins(:skin)
                       .select("skin_items.*, skins.min_float as skin_min_float, skins.max_float as skin_max_float")
                       .find(skin_item.id)

      expect(joined.float_cap).to be_within(0.0001).of(0.7)
      expect(joined.fn_probability_percent).to be_within(0.05).of(10.0)
    end
  end
end
