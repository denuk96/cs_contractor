# == Schema Information
#
# Table name: tradeup_contracts
#
#  id                :integer          not null, primary key
#  tradeup_search_id :integer          not null
#  profit            :float            not null
#  collection        :string           not null
#  data              :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_tradeup_contracts_on_tradeup_search_id             (tradeup_search_id)
#  index_tradeup_contracts_on_tradeup_search_id_and_profit  (tradeup_search_id,profit)
#

class TradeupContract < ApplicationRecord
  belongs_to :tradeup_search

  def parsed_data
    @parsed_data ||= JSON.parse(data, symbolize_names: true)
  end
end
