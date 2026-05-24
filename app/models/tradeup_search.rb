class TradeupSearch < ApplicationRecord
  has_many :tradeup_contracts, dependent: :destroy

  def done?
    status == "done"
  end

  def progress_pct
    return 0 unless total_jobs&.positive?
    (completed_jobs.to_f / total_jobs * 100).round
  end

  def service_args
    p = JSON.parse(params_json, symbolize_names: true)
    {
      price_fee_multiplier:  p[:price_fee_multiplier].to_f,
      max_cost:              p[:max_cost].presence&.to_f,
      cheapest_fill_count:   p[:cheapest_fill_count].to_i,
      minimum_outcome_lose:  p[:minimum_outcome_lose].to_f,
      min_profit:            p[:min_profit].to_f,
      limit_per_collection:  p[:limit_per_collection].to_i,
      max_unique_inputs:     p[:max_unique_inputs].to_i,
      from_rarity:           p[:from_rarity].presence,
      skip_if_price_missing: p[:skip_if_price_missing].to_s == "1",
      consider_float:        p[:consider_float].to_s == "1",
      outcome_price_type:    p[:outcome_price_type].to_sym,
      filler_strategy:       p[:filler_strategy].to_sym,
    }
  end
end
