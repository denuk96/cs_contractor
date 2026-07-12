class ImportSkinsJob < ApplicationJob
  include NotifiesOnFailure

  queue_as :default

  def perform
    Import::Skins.new.call
  end
end