class TradeupWorkerJob < ApplicationJob
  queue_as :default

  def perform(search_id, collection, wear, stattrak)
    search = TradeupSearch.find_by(id: search_id)
    return unless search

    contracts = Tradeups::FindProfitableContracts
      .new(**search.service_args)
      .call_for(collection:, wear:, stattrak:)

    contracts.each do |contract|
      TradeupContract.create!(
        tradeup_search: search,
        profit:     contract.profit,
        collection: contract.collection,
        data:       contract_to_json(contract)
      )
    end
  ensure
    if search
      TradeupSearch.where(id: search_id).update_all("completed_jobs = completed_jobs + 1")
      search.reload
      if search.completed_jobs >= search.total_jobs.to_i && !search.done?
        search.update!(status: "done")
      end
    end
  end

  private

  def contract_to_json(c)
    {
      collection:              c.collection,
      from_rarity:             c.from_rarity,
      to_rarity:               c.to_rarity,
      wear:                    c.wear,
      cost:                    c.cost,
      expected_value:          c.expected_value,
      profit:                  c.profit,
      minimal_expected_value:  c.minimal_expected_value,
      maximum_expected_value:  c.maximum_expected_value,
      cheapest_fill_count:     c.cheapest_fill_count,
      stack: c.stack.map { |s|
        { item_id:    s[:item].id,
          item_name:  s[:item].name,
          item_price: s[:item].latest_steam_price,
          souvenir:   s[:item].souvenir?,
          qty:        s[:qty] }
      },
      outcomes: c.outcomes.map { |o|
        { item_id:     o[:item].id,
          item_name:   o[:item].name,
          probability: o[:probability],
          price:       o[:price] }
      }
    }.to_json
  end
end
