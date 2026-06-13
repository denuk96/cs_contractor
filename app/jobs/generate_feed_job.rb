class GenerateFeedJob < ApplicationJob
  queue_as :default

  def perform
    Feed::GenerateEntries.new.call
    Feed::PruneStaleEntries.new.call
  end
end
