module SkinItems
  class TrendingQuery
    def initialize(options = {})
      @options = options
    end

    def call
      SkinItem.find_by_sql([sql, sql_binds])
    end

    private

    attr_reader :options

    def normalized_rarity(rarity)
      # `rarity` can come in as:
      # - enum integer value (e.g. "2") from a select
      # - enum key string (e.g. "Mid-Spec Grade") from links/APIs
      # - common alias ("Mil-Spec Grade")
      #
      # Data note: historically, rarity exists in *both* `skin_items.rarity` (integer enum)
      # and `skins.rarity` (string). Some datasets only populate one of them, so we accept either.
      rarity_key = rarity.to_s.strip

      rarity_value =
        if rarity_key.match?(/\A\d+\z/)
          rarity_key.to_i
        else
          SkinItem.rarities[rarity_key] || SkinItem.rarities[rarity_key.sub("Mid-Spec", "Mil-Spec")]
        end

      rarity_name = rarity_value.present? ? SkinItem.rarities.key(rarity_value) : rarity_key
      rarity_name_alias = rarity_name.to_s.sub("Mid-Spec", "Mil-Spec")

      {
        value: rarity_value,
        name: rarity_name,
        name_alias: rarity_name_alias
      }
    end

    def apply_rarity_filter!(primary_conditions, binds, rarity)
      normalized = normalized_rarity(rarity)
      return if normalized[:value].blank? && normalized[:name].blank?

      rarity_conditions = []

      if normalized[:value].present?
        rarity_conditions << "skin_items.rarity = :rarity"
        binds[:rarity] = normalized[:value]
      end

      if normalized[:name].present?
        rarity_conditions << "skins.rarity = :rarity_name"
        binds[:rarity_name] = normalized[:name]

        if normalized[:name_alias].present? && normalized[:name_alias] != normalized[:name]
          rarity_conditions << "skins.rarity = :rarity_name_alias"
          binds[:rarity_name_alias] = normalized[:name_alias]
        end
      end

      primary_conditions << "(#{rarity_conditions.join(' OR ')})" if rarity_conditions.any?
    end

    def context
      @context ||= begin
        rarity = options[:rarity]
        wear = options[:wear]
        min_price = options[:min_price]
        max_price = options[:max_price]
        sort_by = options[:sort_by]
        name_query = options[:name]
        category = options[:category]
        start_date = options[:start_date]
        end_date = options[:end_date]
        min_offervolume = options[:min_offervolume]
        max_offervolume = options[:max_offervolume]
        stattrak = options[:stattrak]
        souvenir = options[:souvenir]
        collection = options[:collection]

        binds = {}
        primary_conditions = []

        if rarity.present?
          apply_rarity_filter!(primary_conditions, binds, rarity)
        end
        if wear.present?
          primary_conditions << "skin_items.wear = :wear"
          binds[:wear] = wear
        end
        if stattrak.in?(%w[true false])
          primary_conditions << "skin_items.stattrak = :stattrak"
          binds[:stattrak] = (stattrak == "true")
        end
        if souvenir.in?(%w[true false])
          primary_conditions << "skin_items.souvenir = :souvenir"
          binds[:souvenir] = (souvenir == "true")
        end
        if min_price.present?
          primary_conditions << "skin_items.latest_steam_price >= :min_price"
          binds[:min_price] = min_price
        end
        if max_price.present?
          primary_conditions << "skin_items.latest_steam_price <= :max_price"
          binds[:max_price] = max_price
        end
        if name_query.present?
          primary_conditions << "skin_items.name LIKE :name"
          binds[:name] = "%#{name_query}%"
        end
        if category.present?
          primary_conditions << "skins.category = :category"
          binds[:category] = category
        end

        if collection.present?
          collection = [collection] unless collection.is_a?(Array)
          collection = collection.reject(&:blank?)

          if collection.any?
            sub_conditions = []
            collection.each_with_index do |c, i|
              c_key = "coll_#{i}".to_sym
              c_crate_key = "coll_crate_#{i}".to_sym

              sub_conditions << "(skins.collection_name = :#{c_key} OR skins.crates LIKE :#{c_crate_key})"
              binds[c_key] = c
              binds[c_crate_key] = "%#{c}%"
            end
            primary_conditions << "(#{sub_conditions.join(' OR ')})"
          end
        end

        primary_where = primary_conditions.empty? ? "1=1" : primary_conditions.join(" AND ")

        if end_date.present?
          h1_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id AND date <= :end_date)"
          binds[:end_date] = end_date
        else
          h1_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id)"
        end

        if start_date.present?
          h2_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id AND date <= :start_date)"
          binds[:start_date] = start_date
        elsif sort_by == "top_signals"
          h2_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id " \
                             "AND date <= date(#{h1_date_subquery}, '-10 days'))"
        else
          h2_date_subquery = "(SELECT MIN(date) FROM skin_item_histories WHERE skin_item_id = fi.id)"
        end

        final_where_conditions = []
        if name_query.blank? && sort_by.blank? && collection.blank?
          final_where_conditions << "h1.id IS NOT NULL AND h2.id IS NOT NULL"
          final_where_conditions << "h1.soldtoday > h2.soldtoday"
          final_where_conditions << "h1.buyordervolume > h2.buyordervolume"
          final_where_conditions << "h1.offervolume < h2.offervolume"
        end

        if sort_by == "top_signals"
          final_where_conditions << "h1.id IS NOT NULL AND h2.id IS NOT NULL"
          final_where_conditions << "(CAST(h1.buyordervolume AS REAL) / NULLIF(h1.offervolume, 0)) > 50"
          final_where_conditions << "(CAST(h1.soldtoday AS REAL) / NULLIF(h1.offervolume, 0)) > 0.15"
          final_where_conditions << "h1.offervolume < h2.offervolume"
          final_where_conditions << "h1.buyorderprice > (0.85 * h1.pricelatest)"
        end

        if min_offervolume.present?
          final_where_conditions << "h1.offervolume >= :min_offervolume"
          binds[:min_offervolume] = min_offervolume
        end
        if max_offervolume.present?
          final_where_conditions << "h1.offervolume <= :max_offervolume"
          binds[:max_offervolume] = max_offervolume
        end

        final_where = final_where_conditions.empty? ? "" : "WHERE #{final_where_conditions.join(' AND ')}"

        limit = options[:limit] || 200

        {
          primary_where: primary_where,
          h1_date_subquery: h1_date_subquery,
          h2_date_subquery: h2_date_subquery,
          final_where: final_where,
          order_clause: order_clause(sort_by),
          limit: limit,
          binds: binds
        }
      end
    end

    def sql_binds
      context[:binds]
    end

    def order_clause(sort_by)
      case sort_by
      when "price_asc"
        "latest_steam_price ASC"
      when "price_desc"
        "latest_steam_price DESC"
      when "none"
        "id ASC"
      when "volume_price_divergence"
        "(current_soldtoday - prev_soldtoday) DESC, ABS(current_price - prev_price) ASC"
      when "supply_dry_up"
        "(CAST(current_soldtoday AS REAL) / NULLIF(current_offervolume, 0)) DESC"
      when "buy_order_increase"
        "(current_buyordervolume - prev_buyordervolume) DESC"
      when "top_signals"
        "(CAST(h1.soldtoday AS REAL) / NULLIF(h1.offervolume, 0)) DESC"
      else
        "(current_soldtoday - prev_soldtoday) DESC"
      end
    end

    def sql
      b = context

      <<~SQL
        WITH filtered_items AS (
          SELECT skin_items.*, skins.collection_name, skins.rarity as skin_rarity, skins.crates as skin_crates, skins.min_float as skin_min_float, skins.max_float as skin_max_float FROM skin_items
          JOIN skins ON skins.id = skin_items.skin_id
          WHERE #{b[:primary_where]}
        )
        SELECT
          fi.*,
          h1.date as current_date,
          h2.date as prev_date,
          h1.soldtoday as current_soldtoday,
          h1.buyordervolume as current_buyordervolume,
          h1.offervolume as current_offervolume,
          h1.pricelatest as current_price,
          h1.buyorderprice as current_buyorderprice,
          h1.all_markets_quantity as current_all_markets_quantity,
          h2.pricelatest as prev_price,
          h2.soldtoday as prev_soldtoday,
          h2.buyordervolume as prev_buyordervolume,
          h2.offervolume as prev_offervolume
        FROM filtered_items fi
        LEFT JOIN skin_item_histories h1 ON h1.skin_item_id = fi.id AND h1.date = #{b[:h1_date_subquery]}
        LEFT JOIN skin_item_histories h2 ON h2.skin_item_id = fi.id AND h2.date = #{b[:h2_date_subquery]}
        #{b[:final_where]}
        ORDER BY #{b[:order_clause]}
        LIMIT #{b[:limit]}
      SQL
    end
  end
end
