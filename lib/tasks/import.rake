namespace :import do
  task skins: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::WARN
    ActiveRecord::Base.logger.level = Logger::WARN

    Import::Skins.new.call
  end

  task prices: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::WARN
    Import::SkinItems.new.fetch_webapi_data
  end
end
