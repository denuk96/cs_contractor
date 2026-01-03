class HomeController < ApplicationController
  def index
    trending_items = SkinItem.trending(
      rarity: params[:rarity],
      wear: params[:wear],
      stattrak: params[:stattrak],
      souvenir: params[:souvenir],
      min_price: params[:min_price],
      max_price: params[:max_price],
      sort_by: params[:sort_by],
      name: params[:name],
      category: params[:category],
      start_date: params[:start_date],
      end_date: params[:end_date],
      min_offervolume: params[:min_offervolume],
      max_offervolume: params[:max_offervolume],
      limit: 1000 # Fetch up to 1000 items to paginate
    )
    @trending_items = Kaminari.paginate_array(trending_items).page(params[:page]).per(20)
  end
end
