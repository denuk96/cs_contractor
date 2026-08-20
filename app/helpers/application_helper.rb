module ApplicationHelper
  # CS2 rarity colors, darkened from the in-game palette so they stay legible
  # as text on the light table background (and as badge backgrounds).
  RARITY_COLORS = {
    "Consumer Grade" => "#6e7c91",
    "Base Grade" => "#6e7c91",
    "Default" => "#6e7c91",
    "Industrial Grade" => "#3a7cc4",
    "High Grade" => "#3a7cc4",
    # `skin_items.rarity` stores "Mid-Spec Grade"; `skins.rarity` uses "Mil-Spec Grade".
    "Mid-Spec Grade" => "#3d4fd6",
    "Mil-Spec Grade" => "#3d4fd6",
    "Restricted" => "#8847ff",
    "Remarkable" => "#8847ff",
    "Exotic" => "#8847ff",
    "Classified" => "#b81fc9",
    "Exceptional" => "#b81fc9",
    "Covert" => "#d02b2b",
    "Master" => "#d02b2b",
    "Extraordinary" => "#a37b12",
    "Contraband" => "#a37b12"
  }.freeze

  DEFAULT_RARITY_COLOR = "#6e7c91".freeze

  def rarity_color(rarity)
    RARITY_COLORS.fetch(rarity.to_s, DEFAULT_RARITY_COLOR)
  end

  def rarity_filter_options
    @rarity_filter_options ||= begin
      sticker_rarities = Skin.where(category: "stickers").distinct.pluck(:rarity).compact.sort
      SkinItem.rarities.to_a + sticker_rarities.map { |r| [r, r] }
    end
  end

  def float_range_with_wear_chance(item)
    return "-" if item.float_min.nil? || item.float_max.nil?

    min_s = number_with_precision(item.float_min, precision: 4, strip_insignificant_zeros: true)
    max_s = number_with_precision(item.float_max, precision: 4, strip_insignificant_zeros: true)
    content_tag(:span, "#{min_s}-#{max_s}", class: "text-nowrap")
  end

  def adjusted_float_range(item)
    return "-" if item.float_min.nil? || item.float_max.nil?

    float_cap = item.float_max.to_f - item.float_min.to_f
    return "-" if float_cap <= 0

    wear_name = item.wear
    wear_range = Skin::WEAR_RANGES[wear_name] if wear_name.present?

    if wear_range
      actual_min = [item.float_min.to_f, wear_range.begin].max
      actual_max = [item.float_max.to_f, wear_range.end].min
      return "-" unless actual_min < actual_max

      adj_min = ((actual_min - item.float_min.to_f) / float_cap).round(4)
      adj_max = ((actual_max - item.float_min.to_f) / float_cap).round(4)
    else
      adj_min = 0.0
      adj_max = 1.0
    end

    adj_min_s = number_with_precision(adj_min, precision: 4, strip_insignificant_zeros: true)
    adj_max_s = number_with_precision(adj_max, precision: 4, strip_insignificant_zeros: true)
    content_tag(:span, "#{adj_min_s}-#{adj_max_s}", class: "text-nowrap")
  end

  def wear_abbreviation(wear)
    case wear
    when "Factory New" then "FN"
    when "Minimal Wear" then "MW"
    when "Field-Tested" then "FT"
    when "Well-Worn" then "WW"
    when "Battle-Scarred" then "BS"
    end
  end

  # Slug per rarity for the CSS ramp. Derived from RARITY_COLORS so the two
  # can never drift: every alias that shares a hex shares a slug.
  RARITY_SLUGS = {
    "#6e7c91" => "consumer",
    "#3a7cc4" => "industrial",
    "#3d4fd6" => "milspec",
    "#8847ff" => "restricted",
    "#b81fc9" => "classified",
    "#d02b2b" => "covert",
    "#a37b12" => "extraordinary"
  }.freeze

  def rarity_slug(rarity)
    RARITY_SLUGS.fetch(rarity_color(rarity), "consumer")
  end

  # Turnover zones, as the services define them: <=5% dead, <=15% organic,
  # <=50% squeeze, >50% moon.
  def turnover_zone(percent)
    case percent.to_f
    when ..5  then ["dead", "DEAD"]
    when ..15 then ["organic", "ORGANIC"]
    when ..50 then ["squeeze", "SQUEEZE"]
    else ["moon", "MOON"]
    end
  end

  # Direction is a property of the column, never of the sign: a rising price is
  # good, but rising buy orders mean accumulation just got more expensive.
  # `polarity` names which direction the column treats as good.
  def delta_class(value, polarity: :up_is_good)
    return "flat" if value.nil? || value.to_f.zero?

    rising = value.to_f.positive?
    good = polarity == :up_is_good ? rising : !rising
    good ? "up" : "down"
  end

  def signed_percent(value, precision: 1)
    return nil if value.nil?

    format("%+.#{precision}f%%", value)
  end

  def signed_number(value)
    return nil if value.nil?

    format("%+d", value)
  end

  def signed_currency(value)
    return nil if value.nil?

    "#{value.negative? ? '−' : '+'}#{number_to_currency(value.abs)}"
  end

  # Short tag for the hatched image placeholder, e.g. "AK-47 | Redline" -> "AK-47".
  def item_abbreviation(name)
    name.to_s.split("|").first.to_s.gsub(/\(.*\)/, "").strip.first(5)
  end

  # The collection a row belongs to. `skins.collection_name` is authoritative;
  # older rows only carry the crate list, so fall back to its first entry.
  def item_collection_name(item)
    return item.collection_name if item.collection_name.present?
    return nil if item.skin_crates.blank?

    crates = JSON.parse(item.skin_crates) rescue []
    crates.first
  end

  # Hover explanation for a derived metric. The tooltip layer in the layout
  # reads "Title|Body" off any element carrying data-tip.
  def info_dot(title, body)
    tag.span("i", class: "info-dot", data: { tip: "#{title}|#{body}" }, aria: { label: title })
  end
end
