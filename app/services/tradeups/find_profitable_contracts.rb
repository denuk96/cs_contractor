# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Metrics/ParameterLists
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
                   max_cost: nil,
                   minimum_outcome_lose: 100,
                   skip_if_price_missing: true,
                   consider_float: true,
                   cheapest_fill_count: nil)
      @from_rarity = from_rarity
      @max_unique_inputs = max_unique_inputs
      @price_fee_multiplier = price_fee_multiplier
      @min_profit = min_profit
      @limit_per_collection = limit_per_collection
      @max_cost = max_cost || Float::INFINITY
      @minimum_outcome_lose = minimum_outcome_lose
      @skip_if_price_missing = skip_if_price_missing
      @consider_float = consider_float
      @cheapest_fill_count = cheapest_fill_count
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

        # Get all potential outcomes for the next rarity (all wears)
        all_outcomes = SkinItem.joins(:skin)
                               .where(skins: { collection_name: collection },
                                      rarity: SkinItem.rarities[next_rarity_name],
                                      stattrak:)
                               .not_souvenir
                               .have_prices
                               .distinct

        next if all_outcomes.empty?

        # Get cheapest items from any collection if cheapest_fill_count is set
        cheapest_fillers = if @cheapest_fill_count && @cheapest_fill_count > 0
                             get_cheapest_fillers(rarity_name, wear, stattrak, inputs)
                           else
                             []
                           end

        candidate_stacks(inputs, cheapest_fillers).each do |stack|
          cost = stack.sum { |h| h[:item].latest_steam_price.to_f * h[:qty] }
          next if cost > @max_cost

          # Calculate achievable float range and filter outcomes accordingly
          if @consider_float
            outcomes = filter_outcomes_by_float(stack, all_outcomes)
          else
            # Fall back to same-wear matching
            outcomes = all_outcomes.where(wear:).to_a
          end

          next if outcomes.empty?

          outcome_probs = build_outcome_probabilities(stack, outcomes)
          if @skip_if_price_missing
            next if outcome_probs.size < Skin.where(collection_name: collection, rarity: next_rarity_name).count
          end

          expected_value = outcome_probs.sum { |o| o[:probability] * (o[:price] * @price_fee_multiplier) }
          minimal_expected_value = outcome_probs.map { |o| o[:price] * @price_fee_multiplier }.min
          maximum_expected_value = outcome_probs.map { |o| o[:price] * @price_fee_multiplier }.max
          profit = expected_value - cost

          next if profit < @min_profit

          required_min_ratio = 1.0 - (@minimum_outcome_lose.to_f / 100.0)
          next if minimal_expected_value < (required_min_ratio * cost)

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
            maximum_expected_value:,
            cheapest_fill_count: @cheapest_fill_count
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
              .have_prices
              .group_by(&:rarity_before_type_cast)
              .transform_keys { |rk| SkinItem.rarities.key(rk) }
              .transform_values { |items| items.sort_by { |i| i.latest_steam_price.to_f } }
        end

    # Get cheapest items from ANY collection with matching rarity, wear, and stattrak
    def get_cheapest_fillers(rarity_name, wear, stattrak, exclude_items = [])
      exclude_ids = exclude_items.map(&:id)
      next_rarity_name = next_rarity(rarity_name)

      return [] unless next_rarity_name

      # Find all collections that have items in the next rarity tier
      # This ensures we only use items that can actually be traded up
      valid_collections = Skin.where(rarity: next_rarity_name)
                              .distinct
                              .pluck(:collection_name)

      # Get the wear enum value for comparison
      # Lower quality (higher wear value) is allowed: BS(4) >= WW(3) >= FT(2) >= MW(1) >= FN(0)
      target_wear_value = SkinItem.wears[wear]

      SkinItem.joins(:skin)
              .where(rarity: SkinItem.rarities[rarity_name], stattrak:)
              .where('wear <= ?', target_wear_value)
              .where(skins: { collection_name: valid_collections })
              .where.not(id: exclude_ids)
              .contractable
              .have_prices
              .order('latest_steam_price ASC')
              .limit(10)
              .to_a
    end

    def next_rarity(rarity_name)
      order = SkinItem.rarities.keys
      idx = order.index(rarity_name)
      return nil unless idx && idx + 1 < order.size

      order[idx + 1]
    end

    # Worst-case float assumptions for market items (near the upper bound of each wear)
    WORST_CASE_FLOATS = {
      "Factory New" => 0.063,      # Close to 0.07 cap
      "Minimal Wear" => 0.143,     # Close to 0.15 cap
      "Field-Tested" => 0.37,      # Close to 0.38 cap
      "Well-Worn" => 0.44,         # Close to 0.45 cap
      "Battle-Scarred" => 0.79     # Higher end of BS range
    }.freeze

    # Filter outcomes based on achievable float values from input stack
    def filter_outcomes_by_float(stack, all_outcomes)
      # Calculate average normalized float from inputs
      avg_normalized_float = calculate_average_normalized_float(stack)

      achievable_outcomes = []

      # Group outcomes by unique skin
      all_outcomes.group_by(&:skin_id).each do |skin_id, outcome_items|
        skin = outcome_items.first.skin
        next unless skin.min_float && skin.max_float

        # Calculate expected output float for this skin
        output_float = skin.min_float + (avg_normalized_float * (skin.max_float - skin.min_float))

        # Determine which wear this float corresponds to
        output_wear = float_to_wear(output_float)

        # Find the matching wear variant
        matching_outcome = outcome_items.find { |item| item.wear == output_wear }
        achievable_outcomes << matching_outcome if matching_outcome
      end

      achievable_outcomes
    end

    # Calculate the average normalized float from input stack
    def calculate_average_normalized_float(stack)
      total_normalized = 0.0

      stack.each do |h|
        item = h[:item]
        qty = h[:qty]
        skin = item.skin

        # Get worst-case float for this wear
        input_float = WORST_CASE_FLOATS[item.wear]
        next unless input_float

        # Normalize: (actual_float - min_cap) / (max_cap - min_cap)
        if skin.min_float && skin.max_float && skin.max_float > skin.min_float
          # Clamp float within skin's actual range
          clamped_float = [[input_float, skin.min_float].max, skin.max_float].min
          normalized = (clamped_float - skin.min_float) / (skin.max_float - skin.min_float)
        else
          # Fallback if float data missing
          normalized = input_float
        end

        total_normalized += normalized * qty
      end

      total_normalized / 10.0
    end

    # Map float value to wear category
    # CS2 float ranges: FN(0-0.07), MW(0.07-0.15), FT(0.15-0.38), WW(0.38-0.45), BS(0.45-1.0)
    def float_to_wear(float_value)
      case float_value
      when 0.0...0.07
        "Factory New"
      when 0.07...0.15
        "Minimal Wear"
      when 0.15...0.38
        "Field-Tested"
      when 0.38...0.45
        "Well-Worn"
      else
        "Battle-Scarred"
      end
    end

    # Build stacks of 10 items using up to @max_unique_inputs distinct skins.
    # Simple heuristic: take cheapest k unique inputs (k up to @max_unique_inputs),
    # distribute quantities to total 10 (biased toward the cheapest).
    # If @cheapest_fill_count is set, ensures at least that many of the cheapest item are included.
    def candidate_stacks(inputs, cheapest_fillers = [])
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

        # Strategy D: if cheapest_fill_count is specified and we have fillers from other collections
        if @cheapest_fill_count && @cheapest_fill_count > 0 && cheapest_fillers.any?
          stacks << cheapest_fill_strategy(pool, cheapest_fillers)
        end

        stacks.map { |s| normalize_stack(s) }.uniq { |s| s.map { |h| [h[:item].id, h[:qty]] } }
      end
    end

    def cheapest_fill_strategy(pool, cheapest_fillers)
      # Use the absolute cheapest item available (from any collection)
      cheapest_item = cheapest_fillers.first
      cheapest_count = [@cheapest_fill_count, 10].min
      remaining = 10 - cheapest_count

      stack = [{ item: cheapest_item, qty: cheapest_count }]

      # Distribute remaining slots among target collection items
      if remaining > 0
        per_item = remaining / pool.size
        leftover = remaining % pool.size

        pool.each_with_index do |item, idx|
          qty = per_item + (idx < leftover ? 1 : 0)
          stack << { item: item, qty: qty } if qty > 0
        end
      end

      stack
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
          price: outcome.latest_steam_order_price.to_f
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
# rubocop:enable Metrics/BlockLength, Metrics/ParameterLists
