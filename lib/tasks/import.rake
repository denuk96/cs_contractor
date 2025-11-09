namespace :import do
  task prices: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::WARN
    Import::SkinItems.new.fetch_webapi_data
  end
end
