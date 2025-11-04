namespace :import do
  task prices: :environment do
    Import::SkinItems.new.call
  end
end