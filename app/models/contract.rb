class Contract
  include ActiveModel::Model

  attr_accessor  :collection, :from_rarity, :to_rarity, :stack, :cost, :outcomes, :expected_value, :profit,
                 :minimal_expected_value, :maximum_expected_value, :wear, :cheapest_fill_count

  # stack: [{ item: SkinItem, qty: Integer }, ...]
  # outcomes: [{ item: SkinItem, probability: Float, price: Float }, ...]

  def print_output
    Rails.logger.info "[#{collection}](#{wear}) #{from_rarity} -> #{to_rarity}"
    Rails.logger.info "Cost: $#{cost.round(2)}  EV: $#{expected_value.round(2)}  Profit: $#{profit.round(2)}"
    stack.each { |s| Rails.logger.info "- #{s[:qty]}x #{s[:item].name} ($#{s[:item].latest_steam_price})" }
    Rails.logger.info "Outcomes:"
    outcomes.each do |o|
      probability = o[:probability] * 100
      if cheapest_fill_count.positive?
        probability -= probability / 100.0 * (cheapest_fill_count.to_i * 10)
      end

      Rails.logger.info "  #{probability.round(2)}% -> #{o[:item].name} ($#{o[:price]})"
    end
    if cheapest_fill_count.present?
      Rails.logger.info "  #{(cheapest_fill_count * 10.0)}% -> Trash outcome($0)"
    end
  end
end


