# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ---------------------------------------------------------------------------
# CS2 skins + skin items seed data
#
# Mirrors the shape produced by `Import::Skins` (skins) and `Import::SkinItems`
# (per-wear market items + price history) so the app is usable offline without
# hitting the CSGO-API / Steam endpoints.
# ---------------------------------------------------------------------------

# Price multiplier relative to the best (lowest float) wear available for a skin.
WEAR_PRICE_FACTORS = {
  "Factory New"    => 1.00,
  "Minimal Wear"   => 0.68,
  "Field-Tested"   => 0.45,
  "Well-Worn"      => 0.37,
  "Battle-Scarred" => 0.31
}.freeze

# StatTrak typically commands a premium over the vanilla item.
STATTRAK_PRICE_FACTOR = 1.6

# name, weapon_id are used to build the steam market name + weapon hash.
SKINS = [
  {
    name: "AK-47 | Redline (Field-Tested)", base: "AK-47 | Redline",
    weapon: { id: "weapon_ak47", name: "AK-47" }, category: "Rifles",
    collection: "The Phoenix Collection", crate: "Operation Phoenix Weapon Case",
    rarity: "Classified", min_float: 0.10, max_float: 0.70,
    wears: ["Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 38.50, stattrak: true
  },
  {
    name: "AK-47 | Vulcan", base: "AK-47 | Vulcan",
    weapon: { id: "weapon_ak47", name: "AK-47" }, category: "Rifles",
    collection: "The Huntsman Collection", crate: "Huntsman Weapon Case",
    rarity: "Covert", min_float: 0.00, max_float: 0.90,
    wears: ["Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 165.00, stattrak: true
  },
  {
    name: "AWP | Asiimov", base: "AWP | Asiimov",
    weapon: { id: "weapon_awp", name: "AWP" }, category: "Sniper Rifles",
    collection: "The Phoenix Collection", crate: "Operation Phoenix Weapon Case",
    rarity: "Covert", min_float: 0.18, max_float: 1.00,
    wears: ["Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 110.00, stattrak: true
  },
  {
    name: "AWP | Dragon Lore", base: "AWP | Dragon Lore",
    weapon: { id: "weapon_awp", name: "AWP" }, category: "Sniper Rifles",
    collection: "The Cobblestone Collection", crate: nil,
    rarity: "Covert", min_float: 0.00, max_float: 0.70,
    wears: ["Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 12500.00, stattrak: false, souvenir: true
  },
  {
    name: "M4A4 | Howl", base: "M4A4 | Howl",
    weapon: { id: "weapon_m4a1", name: "M4A4" }, category: "Rifles",
    collection: "The Huntsman Collection", crate: "Huntsman Weapon Case",
    rarity: "Contraband", min_float: 0.00, max_float: 0.40,
    wears: ["Factory New", "Minimal Wear", "Field-Tested"],
    fn_price: 4200.00, stattrak: true
  },
  {
    name: "M4A1-S | Hyper Beast", base: "M4A1-S | Hyper Beast",
    weapon: { id: "weapon_m4a1_silencer", name: "M4A1-S" }, category: "Rifles",
    collection: "The Chroma Collection", crate: "Chroma Case",
    rarity: "Covert", min_float: 0.00, max_float: 1.00,
    wears: ["Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 62.00, stattrak: true
  },
  {
    name: "USP-S | Kill Confirmed", base: "USP-S | Kill Confirmed",
    weapon: { id: "weapon_usp_silencer", name: "USP-S" }, category: "Pistols",
    collection: "The Shadow Collection", crate: "Shadow Case",
    rarity: "Covert", min_float: 0.00, max_float: 1.00,
    wears: ["Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 92.00, stattrak: true
  },
  {
    name: "Glock-18 | Fade", base: "Glock-18 | Fade",
    weapon: { id: "weapon_glock", name: "Glock-18" }, category: "Pistols",
    collection: "The Assault Collection", crate: nil,
    rarity: "Restricted", min_float: 0.00, max_float: 0.08,
    wears: ["Factory New", "Minimal Wear"],
    fn_price: 540.00, stattrak: false
  },
  {
    name: "Desert Eagle | Blaze", base: "Desert Eagle | Blaze",
    weapon: { id: "weapon_deagle", name: "Desert Eagle" }, category: "Pistols",
    collection: "The Dust Collection", crate: nil,
    rarity: "Restricted", min_float: 0.00, max_float: 0.08,
    wears: ["Factory New", "Minimal Wear"],
    fn_price: 420.00, stattrak: false
  },
  {
    name: "P250 | Sand Dune", base: "P250 | Sand Dune",
    weapon: { id: "weapon_p250", name: "P250" }, category: "Pistols",
    collection: "The Dust 2 Collection", crate: nil,
    rarity: "Consumer Grade", min_float: 0.00, max_float: 1.00,
    wears: ["Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"],
    fn_price: 0.05, stattrak: false
  },
  {
    name: "MP9 | Hot Rod", base: "MP9 | Hot Rod",
    weapon: { id: "weapon_mp9", name: "MP9" }, category: "SMGs",
    collection: "The Chroma Collection", crate: "Chroma Case",
    rarity: "Industrial Grade", min_float: 0.00, max_float: 0.08,
    wears: ["Factory New", "Minimal Wear"],
    fn_price: 9.40, stattrak: true
  },
  {
    name: "Nova | Koi", base: "Nova | Koi",
    weapon: { id: "weapon_nova", name: "Nova" }, category: "Shotguns",
    collection: "The Baggage Collection", crate: nil,
    rarity: "Restricted", min_float: 0.06, max_float: 0.20,
    wears: ["Minimal Wear", "Field-Tested"],
    fn_price: 6.20, stattrak: false
  }
].freeze

def steam_market_name(base, wear, stattrak:, souvenir:)
  prefix = "StatTrak™ " if stattrak
  prefix = "Souvenir " if souvenir
  "#{prefix}#{base} (#{wear})"
end

# Build a price-history series that trends "up" (rising demand, shrinking
# supply) so seeded items surface on the default trending view, which compares
# the newest snapshot against the oldest.
def history_series(skin_item, base_price, days: 30)
  start_date = Date.current - (days - 1)

  days.times.map do |i|
    progress = i.to_f / (days - 1)
    price = (base_price * (0.85 + 0.30 * progress)).round(2)

    {
      skin_item_id: skin_item.id,
      date: start_date + i,
      pricelatest: price,
      pricemedian: price,
      pricemedian24h: price,
      pricemedian7d: (price * 0.98).round(2),
      pricemedian30d: (price * 0.92).round(2),
      pricemedian90d: (price * 0.88).round(2),
      # Demand rises over time, supply dries up.
      sold24h: (20 + 60 * progress).round,
      soldtoday: (15 + 55 * progress).round,
      sold7d: (140 + 300 * progress).round,
      sold30d: (600 + 900 * progress).round,
      sold90d: (1800 + 1500 * progress).round,
      soldtotal: (5000 + 4000 * progress).round,
      buyordervolume: (50 + 450 * progress).round,
      buyorderprice: (price * 0.9).round(2),
      buyordermedian: (price * 0.88).round(2),
      buyorderavg: (price * 0.89).round(2),
      offervolume: (800 - 600 * progress).round,
      all_markets_quantity: (1200 - 700 * progress).round,
      all_markets_weighted_median_price: (price * 1.02).round(2),
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

ActiveRecord::Base.transaction do
  SKINS.each do |attrs|
    skin = Skin.find_or_initialize_by(name: attrs[:base])
    skin.assign_attributes(
      object_id: attrs[:base].parameterize,
      collection_name: attrs[:collection],
      rarity: attrs[:rarity],
      category: attrs[:category],
      souvenir: attrs.fetch(:souvenir, false),
      stattrak: attrs.fetch(:stattrak, false),
      min_float: attrs[:min_float],
      max_float: attrs[:max_float],
      wears: attrs[:wears],
      crates: [attrs[:crate]].compact,
      weapon: { "id" => attrs[:weapon][:id], "name" => attrs[:weapon][:name] }
    )
    skin.save!

    # Build (vanilla, stattrak, souvenir) variants requested for this skin.
    variants = [{ stattrak: false, souvenir: false }]
    variants << { stattrak: true, souvenir: false } if attrs.fetch(:stattrak, false)
    variants << { stattrak: false, souvenir: true } if attrs.fetch(:souvenir, false)

    variants.each do |variant|
      attrs[:wears].each do |wear|
        wear_price = attrs[:fn_price] * WEAR_PRICE_FACTORS.fetch(wear)
        wear_price *= STATTRAK_PRICE_FACTOR if variant[:stattrak]
        wear_price = wear_price.round(2)

        name = steam_market_name(attrs[:base], wear,
                                 stattrak: variant[:stattrak], souvenir: variant[:souvenir])

        item = SkinItem.find_or_initialize_by(name: name)
        item.assign_attributes(
          skin: skin,
          rarity: attrs[:rarity],
          wear: wear,
          souvenir: variant[:souvenir],
          stattrak: variant[:stattrak],
          latest_steam_price: wear_price,
          latest_steam_order_price: (wear_price * 0.9).round(2),
          last_steam_price_updated_at: Time.current,
          metadata: {
            "collection" => attrs[:collection],
            "weapon" => attrs[:weapon][:name]
          }
        )
        item.save!

        rows = history_series(item, wear_price)
        SkinItemHistory.upsert_all(rows, unique_by: %i[skin_item_id date])
      end
    end
  end
end

puts "Seeded #{Skin.count} skins, #{SkinItem.count} skin items, " \
     "#{SkinItemHistory.count} price-history rows."
