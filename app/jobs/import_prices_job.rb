class ImportPricesJob < ApplicationJob
  queue_as :default

  def perform
    Import::SkinItems.new.fetch_webapi_data
  end
end