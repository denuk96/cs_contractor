class TradeupSearchOrchestratorJob < ApplicationJob
  queue_as :default

  def perform(search_id)
    search = TradeupSearch.find(search_id)
    search.update!(status: "running")

    combos = []
    Skin.distinct.pluck(:collection_name).compact.each do |collection|
      SkinItem.wears.each_key do |wear|
        combos << [collection, wear, false]
        combos << [collection, wear, true]
      end
    end

    search.update!(total_jobs: combos.size)

    combos.each do |collection, wear, stattrak|
      TradeupWorkerJob.perform_later(search_id, collection, wear, stattrak)
    end
  end
end
