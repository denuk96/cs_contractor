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
    if stattrak.in?(['true', 'false'])
      primary_conditions << "skin_items.stattrak = :stattrak"
      binds[:stattrak] = (stattrak == 'true')
    end
    if souvenir.in?(['true', 'false'])
      primary_conditions << "skin_items.souvenir = :souvenir"
      binds[:souvenir] = (souvenir == 'true')
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

    primary_where = primary_conditions.empty? ? "1=1" : primary_conditions.join(' AND ')

    if end_date.present?
      h1_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id AND date <= :end_date)"
      binds[:end_date] = end_date
    else
      h1_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id)"
    end

    if start_date.present?
      h2_date_subquery = "(SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = fi.id AND date <= :start_date)"
      binds[:start_date] = start_date
    else
      # Default to oldest vs newest
      h2_date_subquery = "(SELECT MIN(date) FROM skin_item_histories WHERE skin_item_id = fi.id)"
    end

    final_where_conditions = []
    if name_query.blank?
      final_where_conditions << "h1.id IS NOT NULL AND h2.id IS NOT NULL"
      if sort_by.blank?
        final_where_conditions << "h1.soldtoday > h2.soldtoday"
        final_where_conditions << "h1.buyordervolume > h2.buyordervolume"
        final_where_conditions << "h1.offervolume < h2.offervolume"
      end
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
                   when 'price_asc'
                     "latest_steam_price ASC"
                   when 'price_desc'
                     "latest_steam_price DESC"
                   when 'none'
                     "id ASC"
                   when 'volume_price_divergence'
                     "(current_soldtoday - prev_soldtoday) DESC, ABS(current_price - prev_price) ASC"
                   when 'supply_dry_up'
                     "(CAST(current_soldtoday AS REAL) / NULLIF(current_offervolume, 0)) DESC"
                   when 'buy_order_increase'
                     "(current_buyordervolume - prev_buyordervolume) DESC"
                   else
                     "(current_soldtoday - prev_soldtoday) DESC"
                   end

    sql = <<-SQL
      WITH filtered_items AS (
        SELECT skin_items.* FROM skin_items
        #{category_join}
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
        h2.pricelatest as prev_price,
        h2.soldtoday as prev_soldtoday,
        h2.buyordervolume as prev_buyordervolume,
        h2.offervolume as prev_offervolume
      FROM filtered_items fi
      LEFT JOIN skin_item_histories h1 ON h1.skin_item_id = fi.id AND h1.date = #{h1_date_subquery}
      LEFT JOIN skin_item_histories h2 ON h2.skin_item_id = fi.id AND h2.date = #{h2_date_subquery}
      #{final_where}
      ORDER BY #{order_clause}
      LIMIT 50
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
