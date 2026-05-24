class TradeupSearchesController < ApplicationController
  RARITY_OPTIONS = [
    "Consumer Grade", "Industrial Grade", "Mid-Spec Grade",
    "Restricted", "Classified", "Covert"
  ].freeze

  def new
    @params = default_params
    @recent_searches = TradeupSearch.order(created_at: :desc).limit(20)
  end

  def create
    @params = search_params
    search = TradeupSearch.create!(params_json: @params.to_json)
    TradeupSearchOrchestratorJob.perform_later(search.id)
    redirect_to tradeup_search_path(search)
  end

  def show
    @search = TradeupSearch.find(params[:id])
    @contracts = @search.tradeup_contracts.order(profit: :desc)
  end

  private

  def search_params
    params.require(:tradeup_search).permit(
      :price_fee_multiplier, :max_cost, :cheapest_fill_count,
      :minimum_outcome_lose, :min_profit, :limit_per_collection,
      :max_unique_inputs, :from_rarity, :skip_if_price_missing,
      :consider_float, :outcome_price_type, :filler_strategy
    )
  end

  def default_params
    {
      price_fee_multiplier:  0.85,
      max_cost:              110.0,
      cheapest_fill_count:   3,
      minimum_outcome_lose:  0,
      min_profit:            5.0,
      limit_per_collection:  3,
      max_unique_inputs:     10,
      from_rarity:           "",
      skip_if_price_missing: "1",
      consider_float:        "0",
      outcome_price_type:    "latest_steam_price",
      filler_strategy:       "cheapest_any",
    }
  end
end
