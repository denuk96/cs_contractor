namespace :import do
  task prices: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::DEBUG
    Import::SkinItems.new.call
    # SkinItem.joins(:skin)
    #         .where.not(skin: {category: %w[Gloves Knives]})
    #         .where(last_steam_price_updated_at: nil)
    #         .not_souvenir
    #         .order(id: :asc)
    #         .find_each do |item|
    #   item.update_latest_price
    #   sleep rand(3..6)
    # rescue => e
    #   Rails.logger.error e.message
    #   Rails.logger.error e.backtrace.join("\n")
    #
    #   sleep 60*5
    # end
  end
end
