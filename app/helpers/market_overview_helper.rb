module MarketOverviewHelper
  # Renders an aggregated market metric in the unit its chart uses.
  def market_metric(value, format)
    case format
    when :currency then number_to_currency(value, precision: 0)
    when :percent  then "#{number_with_precision(value, precision: 1)}%"
    when :ratio    then "#{number_with_precision(value, precision: 2)}x"
    else number_with_delimiter(value.round)
    end
  end
end
