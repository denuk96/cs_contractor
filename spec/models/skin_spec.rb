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

require "rails_helper"

RSpec.describe Skin, type: :model do
  describe "#float_cap" do
    it "returns max_float - min_float" do
      skin = build(:skin, min_float: 0.0, max_float: 0.7)

      expect(skin.float_cap).to be_within(0.0001).of(0.7)
    end
  end

  describe "#fn_probability_percent" do
    it "matches the example: range 0.7 -> ~10%" do
      skin = build(:skin, min_float: 0.0, max_float: 0.7)

      expect(skin.fn_probability_percent).to be_within(0.05).of(10.0)
    end

    it "matches the example: range 0.94 -> ~0.6%" do
      skin = build(:skin, min_float: 0.0, max_float: 0.94)

      expect(skin.fn_probability_percent).to be_within(0.05).of(0.6)
    end

    it "is 0% when the skin cannot have Factory New" do
      skin = build(:skin, min_float: 0.10, max_float: 0.70)

      expect(skin.can_have_factory_new?).to eq(false)
      expect(skin.fn_probability_percent).to eq(0.0)
    end

    it "handles zero float range" do
      skin_fn = build(:skin, min_float: 0.01, max_float: 0.01)
      skin_no_fn = build(:skin, min_float: 0.20, max_float: 0.20)

      expect(skin_fn.fn_probability_percent).to eq(100.0)
      expect(skin_no_fn.fn_probability_percent).to eq(0.0)
    end
  end

  describe "#best_possible_wear" do
    it "returns the closest highest wear when Factory New is not possible" do
      skin = build(:skin, min_float: 0.10, max_float: 0.70)

      expect(skin.best_possible_wear).to eq("Minimal Wear")
    end
  end
end
