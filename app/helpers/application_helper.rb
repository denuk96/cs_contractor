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
end
