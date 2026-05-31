class ImportSkinsJob < ApplicationJob
  queue_as :default

  def perform
    Import::Skins.new.call
  end
end