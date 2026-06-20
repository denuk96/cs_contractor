class HomeController < ApplicationController
  def index
    params[:souvenir] ||= 'false'

    # For CSV/JSON export, we want a larger limit or all items.
    # For HTML view, we paginate.
    limit = (request.format.csv? || request.format.json?) ? 5000 : 1000

    trending_items = SkinItems::TrendingQuery.new(
      rarity: params[:rarity],
      wear: params[:wear],
      stattrak: params[:stattrak],
      souvenir: params[:souvenir],
      in_game_store: params[:in_game_store],
      min_price: params[:min_price],
      max_price: params[:max_price],
      sort_by: params[:sort_by],
      name: params[:name],
      category: params[:category],
      collection: params[:collection],
      start_date: params[:start_date],
      end_date: params[:end_date],
      min_offervolume: params[:min_offervolume],
      max_offervolume: params[:max_offervolume],
      min_buyordervolume: params[:min_buyordervolume],
      max_buyordervolume: params[:max_buyordervolume],
      min_buy_wall_ratio: params[:min_buy_wall_ratio],
      min_turnover: params[:min_turnover],
      starred_only: params[:starred_only] == "1",
      limit: limit
    ).call

    @starred_ids = StarredSkinItem.pluck(:skin_item_id).to_set

    respond_to do |format|
      format.html do
        @trending_items = Kaminari.paginate_array(trending_items).page(params[:page]).per(100)
      end

      format.csv do
        csv_data = CsvExportService.new(trending_items).call
        send_data csv_data, filename: "trending_items-#{Date.today}.csv"
      end

      format.json do
        json_data = JsonExportService.new(trending_items).call
        send_data json_data, filename: "trending_items-#{Date.today}.json", type: :json, disposition: "attachment"
      end
    end
  end
end
