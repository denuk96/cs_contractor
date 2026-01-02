class HomeController < ApplicationController
  def index
    @trending_items = SkinItem.trending(
      rarity: params[:rarity],
      min_price: params[:min_price],
      max_price: params[:max_price],
      sort_by: params[:sort_by],
      name: params[:name],
      category: params[:category],
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
  end
end
