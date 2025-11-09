namespace :tradeups do
  task find: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::WARN
    tradeup = Tradeups::FindProfitableContracts.new(price_fee_multiplier: 0.85,
                                                    max_cost: 400.0,
                                                    cheapest_fill_count: 2,
                                                    min_profit: 1.0)
    contracts = tradeup.call
    contracts.each do |c|
      p "-------------------------------------------------------"
      c.print_output
    end
  end
end
