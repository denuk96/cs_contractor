namespace :tradeups do
  task find: :environment do
    puts "Starting tradeup calculation..."
    path = Rails.root.join("tmp", "contracts.txt")
    FileUtils.mkdir_p(path.dirname)
    File.open(path, "w") {} # truncate/create
    Rails.logger = Logger.new(path)
    Rails.logger.level = Logger::INFO
    ActiveRecord::Base.logger = nil
    tradeup = Tradeups::FindProfitableContracts.new(price_fee_multiplier: 0.85,
                                                    max_cost: 400.0,
                                                    cheapest_fill_count: 2,
                                                    min_profit: 1.0)
    contracts = tradeup.call
    contracts.each_with_index do |c, index|
      Rails.logger.info "------------------------ #{index+1} ------------------------------"
      c.print_output
    end

    puts "Tradeup calculation is finished."
  end
end
