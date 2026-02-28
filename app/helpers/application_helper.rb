module ApplicationHelper
  def rarity_filter_options
    @rarity_filter_options ||= begin
      sticker_rarities = Skin.where(category: "stickers").distinct.pluck(:rarity).compact.sort
      SkinItem.rarities.to_a + sticker_rarities.map { |r| [r, r] }
    end
  end

  def float_range_with_wear_chance(item)
    return "-" if item.float_min.nil? || item.float_max.nil?

    min_s = number_with_precision(item.float_min, precision: 2, strip_insignificant_zeros: true)
    max_s = number_with_precision(item.float_max, precision: 2, strip_insignificant_zeros: true)

    float_range_s = "#{min_s}-#{max_s}"

    if item.can_have_factory_new?
      prob = item.fn_probability_percent
      return content_tag(:span, float_range_s, class: "text-nowrap") if prob.nil?

      prob_s = number_to_percentage(prob, precision: 1, strip_insignificant_zeros: true)
      return content_tag(:span, float_range_s, class: "text-nowrap") if prob_s.blank?

      fn_class = prob.to_f > 5 ? "text-success" : "text-danger"
      fn_part = safe_join(["(", content_tag(:span, "#{prob_s} FN", class: fn_class), ")"])

      return content_tag(:span, safe_join([float_range_s, fn_part]), class: "text-nowrap")
    end

    wear_abbr = wear_abbreviation(item.best_possible_wear)
    return content_tag(:span, float_range_s, class: "text-nowrap") if wear_abbr.blank?

    content_tag(:span, "#{float_range_s}(#{wear_abbr})", class: "text-nowrap")
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
