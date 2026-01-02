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
    min_price = options[:min_price]
    max_price = options[:max_price]
    sort_by = options[:sort_by]
    name_query = options[:name]
    category = options[:category]
    start_date = options[:start_date]
    end_date = options[:end_date]

    conditions = []
    # Only apply trending conditions if the user is not searching for a specific name.
    if name_query.blank?
      conditions.concat([
        "h1.soldtoday > h2.soldtoday",
        "h1.buyordervolume > h2.buyordervolume",
        "h1.offervolume < h2.offervolume"
      ])
    end

    binds = {}
    joins = []

    if rarity.present?
      conditions << "skin_items.rarity = :rarity"
      binds[:rarity] = rarity
    end

    if min_price.present?
      conditions << "skin_items.latest_steam_price >= :min_price"
      binds[:min_price] = min_price
    end

    if max_price.present?
      conditions << "skin_items.latest_steam_price <= :max_price"
      binds[:max_price] = max_price
    end

    if name_query.present?
      conditions << "skin_items.name LIKE :name"
      binds[:name] = "%#{name_query}%"
    end

    if category.present?
      joins << "JOIN skins ON skins.id = skin_items.skin_id"
      conditions << "skins.category = :category"
      binds[:category] = category
    end

    h1_date_condition = "1=1"
    if end_date.present?
        h1_date_condition = "date <= :end_date"
        binds[:end_date] = end_date
    end

    h2_date_condition = "date < h1.date"
    if start_date.present?
        h2_date_condition = "date <= :start_date"
        binds[:start_date] = start_date
    end

    order_clause = case sort_by
                   when 'price_asc'
                     "skin_items.latest_steam_price ASC"
                   when 'price_desc'
                     "skin_items.latest_steam_price DESC"
                   when 'none'
                     "skin_items.id ASC"
                   else
                     "(h1.soldtoday - h2.soldtoday) DESC"
                   end

    where_clause = conditions.present? ? conditions.join(' AND ') : "1=1"

    sql = <<-SQL
      SELECT skin_items.*,
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
      FROM skin_items
      JOIN skin_item_histories h1 ON h1.skin_item_id = skin_items.id
      JOIN skin_item_histories h2 ON h2.skin_item_id = skin_items.id
      #{joins.join(' ')}
      WHERE h1.date = (SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = skin_items.id AND #{h1_date_condition})
      AND h2.date = (SELECT MAX(date) FROM skin_item_histories WHERE skin_item_id = skin_items.id AND #{h2_date_condition})
      AND #{where_clause}
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
