# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Tradeups
  class FindProfitableContracts
    # Options:
    # - from_rarity: restrict search to a specific rarity name (e.g., "Mid-Spec Grade")
    # - max_unique_inputs: limit number of distinct input skins per stack to keep combinations small (default 5)
    # - price_fee_multiplier: e.g., 0.87 to model Steam fee on sell price (default 1.0)
    # - min_profit: only return contracts with profit >= this (default 0)
    # - limit_per_collection: cap results per collection (default 10)
    def initialize(from_rarity: nil,
                   max_unique_inputs: 10,
                   price_fee_multiplier: 1.0,
                   min_profit: 0.0,
                   limit_per_collection: 10,
                   max_cost: nil)
      @from_rarity = from_rarity
      @max_unique_inputs = max_unique_inputs
      @price_fee_multiplier = price_fee_multiplier
      @min_profit = min_profit
      @limit_per_collection = limit_per_collection
      @max_cost = max_cost || Float::INFINITY
    end

    def call
      results = []
      collections.each do |collection|
        SkinItem.wears.each_key do |wear|
          generate_contracts(collection:, wear:, stattrak: false, results:)
          generate_contracts(collection:, wear:, stattrak: true, results:)
        end
      end

      rank(results)
    end

    private

    def generate_contracts(collection:, wear:, stattrak: false, results: [])
      rarities = rarity_groups_for(collection, wear, stattrak)
      rarities.each do |rarity_name, inputs|
        next unless next_rarity_name = next_rarity(rarity_name)
        next if @from_rarity && rarity_name != @from_rarity

        outcomes = SkinItem.joins(:skin)
                           .where(skins: { collection_name: collection },
                                  rarity: SkinItem.rarities[next_rarity_name],
                                  stattrak:,
                                  wear:)
                           .not_souvenir
                           .distinct.to_a
        next if outcomes.empty?

        candidate_stacks(inputs).each do |stack|
          cost = stack.sum { |h| h[:item].latest_steam_price.to_f * h[:qty] }
          next if cost > @max_cost

          outcome_probs = build_outcome_probabilities(stack, outcomes)
          expected_value = outcome_probs.sum { |o| o[:probability] * (o[:price] * @price_fee_multiplier) }
          minimal_expected_value = outcome_probs.map { |o| o[:price] * @price_fee_multiplier }.min
          maximum_expected_value = outcome_probs.map { |o| o[:price] * @price_fee_multiplier }.max
          profit = expected_value - cost

          next if profit < @min_profit

          results << Contract.new(
            collection: collection,
            from_rarity: rarity_name,
            wear:,
            to_rarity: next_rarity_name,
            stack: stack,
            cost: cost,
            outcomes: outcome_probs,
            expected_value:,
            profit:,
            minimal_expected_value:,
            maximum_expected_value:
          )
        end
      end

    end

    def collections
      Skin.group(:collection_name).select(:collection_name).pluck(:collection_name)
    end

    def rarity_groups_for(collection, wear, stattrak)
      SkinItem.joins(:skin)
              .where(skins: { collection_name: collection })
              .where(stattrak:, wear:)
              .contractable
              .group_by(&:rarity_before_type_cast)
              .transform_keys { |rk| SkinItem.rarities.key(rk) }
              .transform_values { |items| items.sort_by { |i| i.latest_steam_price.to_f } }
    end

    def next_rarity(rarity_name)
      order = SkinItem.rarities.keys
      idx = order.index(rarity_name)
      return nil unless idx && idx + 1 < order.size

      order[idx + 1]
    end

    # Build stacks of 10 items using up to @max_unique_inputs distinct skins.
    # Simple heuristic: take cheapest k unique inputs (k up to @max_unique_inputs),
    # distribute quantities to total 10 (biased toward the cheapest).
    def candidate_stacks(inputs)
      return [] if inputs.empty?

      uniq_limits = (1..[@max_unique_inputs, inputs.size].min).to_a
      cheapest = inputs.first( @max_unique_inputs )

      uniq_limits.flat_map do |k|
        pool = cheapest.first(k)
        next [] if pool.empty?

        stacks = []
        # Strategy A: all 10 of the single cheapest when k == 1
        if k == 1
          stacks << [{ item: pool.first, qty: 10 }]
        else
          # Strategy B: greedy fill by increasing price
          stacks << greedy_fill(pool)
          # Strategy C: even split then adjust
          stacks << even_split(pool)
        end

        stacks.map { |s| normalize_stack(s) }.uniq { |s| s.map { |h| [h[:item].id, h[:qty]] } }
      end
    end

    def greedy_fill(pool)
      remaining = 10
      stack = []
      pool.sort_by { |i| i.latest_steam_price.to_f }.each_with_index do |item, idx|
        qty = idx == pool.size - 1 ? remaining : [remaining, (10 / pool.size.to_f).ceil].min
        qty = [qty, remaining].min
        remaining -= qty
        stack << { item: item, qty: qty } if qty.positive?
        break if remaining.zero?
      end
      # If still remaining, fill with cheapest
      if remaining.positive?
        stack[0][:qty] += remaining
      end
      stack
    end

    def even_split(pool)
      base = 10 / pool.size
      rem = 10 % pool.size
      pool.each_with_index.map do |item, idx|
        { item: item, qty: base + (idx < rem ? 1 : 0) }
      end
    end

    def normalize_stack(stack)
      stack = stack.select { |h| h[:qty].to_i > 0 }
      # ensure total 10
      total = stack.sum { |h| h[:qty] }
      if total != 10
        delta = 10 - total
        stack[0][:qty] += delta
      end
      stack.sort_by { |h| [h[:item].latest_steam_price.to_f, h[:item].id] }
    end

    # Probabilities: for each outcome skin O, probability is sum over inputs that can produce O of (qty of that input)/10 divided by number of eligible outcomes.
    # In classic trade-ups within a single collection and rarity, any of the next-rarity skins in that collection are eligible for each input skin.
    def build_outcome_probabilities(stack, outcomes)
      # Each input copy contributes 1/10 chance spread uniformly across all next-rarity outcomes.
      per_copy_share = 1.0 / 10.0
      per_copy_outcome_share = per_copy_share / outcomes.size

      totals = Hash.new(0.0)
      outcomes.each { |o| totals[o] = 0.0 }

      stack.each do |h|
        qty = h[:qty].to_i
        outcomes.each do |outcome|
          totals[outcome] += qty * per_copy_outcome_share
        end
      end

      totals.map do |outcome, prob|
        {
          item: outcome,
          probability: prob,
          price: outcome.latest_steam_price.to_f
        }
      end
    end

    def rank(contracts)
      contracts.sort_by { |c| [-c.profit, c.cost] }
               .group_by(&:collection)
               .flat_map { |_col, list| list.first(@limit_per_collection) }
    end
  end
end
# rubocop:enable Metrics/BlockLength
