class Contract
  include ActiveModel::Model

  attr_accessor  :collection, :from_rarity, :to_rarity, :stack, :cost, :outcomes, :expected_value, :profit,
                 :minimal_expected_value, :maximum_expected_value, :wear

  # stack: [{ item: SkinItem, qty: Integer }, ...]
  # outcomes: [{ item: SkinItem, probability: Float, price: Float }, ...]

  def print_output
    Rails.logger.debug "[#{collection}](#{wear}) #{from_rarity} -> #{to_rarity}"
    Rails.logger.debug "Cost: $#{cost.round(2)}  EV: $#{expected_value.round(2)}  Profit: $#{profit.round(2)}"
    stack.each { |s| Rails.logger.debug "- #{s[:qty]}x #{s[:item].name} ($#{s[:item].latest_steam_price})" }
    Rails.logger.debug "Outcomes:"
    outcomes.each { |o| Rails.logger.debug "  #{(o[:probability]*100).round(2)}% -> #{o[:item].name} ($#{o[:price]})" }
  end
end


