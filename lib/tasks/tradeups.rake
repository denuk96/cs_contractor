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
                                                    max_cost: 110.0,
                                                    cheapest_fill_count: 3,
                                                    minimum_outcome_lose: 0,
                                                    min_profit: 5.0,
                                                    limit_per_collection: 3)
    contracts = tradeup.call
    contracts.each_with_index do |c, index|
      Rails.logger.info "------------------------ #{index+1} ------------------------------"
      c.print_output
    end

    puts "Tradeup calculation is finished."
  end

  task find_mixed: :environment do
    puts "Starting tradeup calculation..."
    path = Rails.root.join("tmp", "contracts_mixed.txt")
    FileUtils.mkdir_p(path.dirname)
    File.open(path, "w") {} # truncate/create
    Rails.logger = Logger.new(path)
    Rails.logger.level = Logger::INFO
    ActiveRecord::Base.logger = nil
    tradeup = Tradeups::FindProfitableContracts.new(price_fee_multiplier: 0.85,
                                                    max_cost: 110.0,
                                                    cheapest_fill_count: 3,
                                                    minimum_outcome_lose: 0,
                                                    min_profit: 10.0,
                                                    limit_per_collection: 3,
                                                    filler_strategy: :mixed_high_wear)
    contracts = tradeup.call
    contracts.each_with_index do |c, index|
      Rails.logger.info "------------------------ #{index+1} ------------------------------"
      c.print_output
    end

    puts "Tradeup calculation is finished."
  end

  task find_safe: :environment do
    puts "Starting tradeup calculation..."
    path = Rails.root.join("tmp", "contracts_safe.txt")
    FileUtils.mkdir_p(path.dirname)
    File.open(path, "w") {} # truncate/create
    Rails.logger = Logger.new(path)
    Rails.logger.level = Logger::INFO
    ActiveRecord::Base.logger = nil
    tradeup = Tradeups::FindProfitableContracts.new(price_fee_multiplier: 0.87,
                                                    max_cost: 100.0,
                                                    cheapest_fill_count: 1,
                                                    minimum_outcome_lose: 0,
                                                    min_profit: 1.0,
                                                    limit_per_collection: 2)
    contracts = tradeup.call
    contracts.each_with_index do |c, index|
      Rails.logger.info "------------------------ #{index+1} ------------------------------"
      c.print_output
    end

    puts "Tradeup calculation is finished."
  end
end
