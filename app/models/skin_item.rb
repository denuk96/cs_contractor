# == Schema Information
#
# Table name: skin_items
#
#  id                          :integer          not null, primary key
#  name                        :string
#  rarity                      :integer
#  wear                        :integer
#  souvenir                    :boolean
#  stattrak                    :boolean
#  latest_steam_price          :float
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  skin_id                     :integer
#  last_steam_price_updated_at :datetime
#  metadata                    :text
#  latest_steam_order_price    :float
#
# Indexes
#
#  index_skin_items_on_name     (name) UNIQUE
#  index_skin_items_on_skin_id  (skin_id)
#

class SkinItem < ApplicationRecord
  belongs_to :skin
  has_many :skin_item_histories, dependent: :destroy

  serialize :metadata, type: Hash, default: {}, coder: JSON

  enum :rarity, {
    "Consumer Grade" => 0,
    "Industrial Grade" => 1,
    "Mid-Spec Grade" => 2,
    "Restricted" => 3,
    "Classified" => 4,
    "Covert" => 5,
    "Extraordinary" => 6,
    "Contraband" => 7
  }

  enum :wear, {
    "Factory New" => 0,
    "Minimal Wear" => 1,
    "Field-Tested" => 2,
    "Well-Worn" => 3,
    "Battle-Scarred" => 4
  }

  scope :not_souvenir, -> { where(souvenir: false) }
  scope :contractable, -> {
    joins(:skin)
      .where.not(rarity: %w[Extraordinary Contraband])
         .where(skins: { category: %w[Rifles SMGs Pistols Heavy Equipment] })
         .where(souvenir: false)
  }
  scope :have_prices, -> { where.not(latest_steam_price: nil) }

  def self.trending(options = {})
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
    limit = options[:limit] || 200

    binds = {}
    
    primary_conditions = []
    if rarity.present?
      primary_conditions << "skin_items.rarity = :rarity"
      binds[:rarity] = rarity
    end
    if wear.present?
      primary_conditions << "skin_items.wear = :wear"
      binds[:wear] = wear
    end
    if stattrak.in?(["true", "false"])
      primary_conditions << "skin_items.stattrak = :stattrak"
      binds[:stattrak] = (stattrak == "true")
    end
    if souvenir.in?(["true", "false"])
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

    category_join = ""
    if category.present?
      category_join = "JOIN skins ON skins.id = skin_items.skin_id"
      primary_conditions << "skins.category = :category"
      binds[:category] = category
    end

    if collection.present?
      # Ensure collection is an array
      collection = [collection] unless collection.is_a?(Array)
      # Filter out empty strings
      collection = collection.reject(&:blank?)
      
      if collection.any?
        # If we haven't joined skins yet, do it now
        unless category.present?
          category_join = "JOIN skins ON skins.id = skin_items.skin_id"
        end
        
        # Handle multiple collections
        placeholders = collection.map.with_index { |_, i| ":collection_#{i}" }.join(", ")
        primary_conditions << "skins.collection_name IN (#{placeholders})"
        collection.each_with_index { |c, i| binds["collection_#{i}".to_sym] = c }
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
      h2_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id AND date <= date(#{h1_date_subquery}, '-10 days'))"
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
      # 1. Buy Wall Ratio > 50
      final_where_conditions << "(CAST(h1.buyordervolume AS REAL) / NULLIF(h1.offervolume, 0)) > 50"
      # 2. Turnover Rate > 15%
      final_where_conditions << "(CAST(h1.soldtoday AS REAL) / NULLIF(h1.offervolume, 0)) > 0.15"
      # 3. Supply dropping (current < previous)
      final_where_conditions << "h1.offervolume < h2.offervolume"
      # 4. Wall Proximity > 0.85
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

    order_clause = case sort_by
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

    sql = <<-SQL
      WITH filtered_items AS (
        SELECT skin_items.*, skins.collection_name, skins.rarity as skin_rarity, skins.crates as skin_crates FROM skin_items
        JOIN skins ON skins.id = skin_items.skin_id
        WHERE #{primary_where}
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
      LEFT JOIN skin_item_histories h1 ON h1.skin_item_id = fi.id AND h1.date = #{h1_date_subquery}
      LEFT JOIN skin_item_histories h2 ON h2.skin_item_id = fi.id AND h2.date = #{h2_date_subquery}
      #{final_where}
      ORDER BY #{order_clause}
      LIMIT #{limit}
    SQL
    
    find_by_sql([sql, binds])
  end

  def update_latest_price
    result = SteamApi.price_overview(name, timeout: 10, open_timeout: 5)
    unless result[:success]
      Rails.logger.warn "Failed to get price for #{name}: #{result.inspect}"
      return false
    end

    return false if result[:lowest_price].nil?

    Rails.logger.info "Updating price for #{name}: #{result.inspect}"
    update(latest_steam_price: result[:lowest_price].delete("$").to_f, last_steam_price_updated_at: Time.zone.now)
  end

  def fetch_order_activity
    SteamWebApi.new.orders_activity(name)
  end
end
