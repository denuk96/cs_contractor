namespace :import do
  task skins: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::WARN
    ActiveRecord::Base.logger.level = Logger::WARN

    Import::Skins.new.call
  end

  task :prices, [:validate_last_run] => :environment do |_, args|
    # Rails.logger = Logger.new(STDOUT)
    Rails.logger = Logger.new(Rails.root.join('log', 'import.log'))
    Rails.logger.level = Logger::INFO

    last_run_file = Rails.root.join('tmp', 'import_prices_last_run.txt')
    validate_last_run = args[:validate_last_run].to_s.downcase == 'true'

    if validate_last_run && File.exist?(last_run_file)
      last_run_time = File.read(last_run_file).to_datetime
      if last_run_time > 3.hours.ago
        Rails.logger.info "Prices import skipped. Last run was at #{last_run_time}. Less than 3 hours ago."
        exit 1
      end
    end

    Rails.logger.info "Starting prices import..."
    Import::SkinItems.new.fetch_webapi_data
    File.write(last_run_file, Time.current.to_s)
    Rails.logger.info "Prices import finished. Last run timestamp saved."
  end
end
