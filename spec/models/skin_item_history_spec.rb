# == Schema Information
#
# Table name: skin_item_histories
#
#  id             :integer          not null, primary key
#  skin_item_id   :integer          not null
#  pricelatest    :float
#  pricemedian    :float
#  pricemedian24h :float
#  pricemedian7d  :float
#  pricemedian30d :float
#  pricemedian90d :float
#  sold24h        :integer
#  sold7d         :integer
#  sold30d        :integer
#  sold90d        :integer
#  soldtotal      :integer
#  soldtoday      :integer
#  buyordervolume :integer
#  buyorderprice  :float
#  buyordermedian :float
#  buyorderavg    :float
#  offervolume    :integer
#  date           :date             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_skin_item_histories_on_skin_item_id           (skin_item_id)
#  index_skin_item_histories_on_skin_item_id_and_date  (skin_item_id,date) UNIQUE
#

require 'rails_helper'

RSpec.describe SkinItemHistory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
