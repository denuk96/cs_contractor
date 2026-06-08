namespace :import do
  task skins: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::WARN
    ActiveRecord::Base.logger.level = Logger::WARN

    Import::Skins.new.call
  end

  task :prices, [:validate_last_run] => :environment do |_, args|
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::INFO

    last_run_file = Rails.root.join('storage', 'import_prices_last_run.txt')
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

  desc "Backfill skin_item_history_prices from previously stored history metadata"
  task backfill_market_prices: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::INFO

    # Raw SQL predicate: `metadata` is a serialized Hash column, so passing a
    # String like "" through the AR query builder would try to dump it via the
    # Hash serializer and raise SerializationTypeMismatch. Filter on the stored
    # text directly instead.
    with_metadata = SkinItemHistory.where("metadata IS NOT NULL AND metadata != ''")
                                   .left_joins(:market_prices)
                                   .where(market_prices: { id: nil })

    total = with_metadata.count
    done = 0

    with_metadata.find_each(batch_size: 500) do |history|
      next unless history.metadata.is_a?(Hash)

      Import::MarketPrices.call(history.id, history.metadata)
      done += 1
      Rails.logger.info "Backfilled #{done}/#{total} histories" if (done % 1000).zero?
    end

    Rails.logger.info "Done. Backfilled market prices for #{done} histories."
  end
end
