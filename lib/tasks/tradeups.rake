namespace :tradeups do
  task find: :environment do
    Rails.logger = Logger.new(STDOUT)
    tradeup = Tradeups::FindProfitableContracts.new(price_fee_multiplier: 0.85, minimum_outcome_lose: 20.0, max_cost: 200.0)
    contracts = tradeup.call
    contracts.each do |c|
      p "-------------------------------------------------------"
      c.print_output
    end
  end
end
