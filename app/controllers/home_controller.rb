class HomeController < ApplicationController
  def index
    # Default Souvenir filter to 'false' (No) if not specified
    params[:souvenir] ||= 'false'

    # For CSV export, we want a larger limit or all items.
    # For HTML view, we paginate.
    limit = request.format.csv? ? 5000 : 1000

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
      limit: limit
    )

    respond_to do |format|
      format.html do
        @trending_items = Kaminari.paginate_array(trending_items).page(params[:page]).per(100)
      end

      format.csv do
        csv_data = CsvExportService.new(trending_items).call
        send_data csv_data, filename: "trending_items-#{Date.today}.csv"
      end
    end
  end
end
