class TradeupContract < ApplicationRecord
  belongs_to :tradeup_search

  def parsed_data
    @parsed_data ||= JSON.parse(data, symbolize_names: true)
  end
end
