class SyncSteamStoreFlagsJob < ApplicationJob
  queue_as :default

  def perform
    Steam::SyncSkinItemFlags.new.call
  end
end
