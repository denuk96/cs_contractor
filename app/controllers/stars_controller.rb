class StarsController < ApplicationController
  before_action :set_skin_item

  def create
    StarredSkinItem.find_or_create_by(skin_item_id: @skin_item.id)
    render_star
  end

  def destroy
    StarredSkinItem.where(skin_item_id: @skin_item.id).destroy_all
    render_star
  end

  private

  def set_skin_item
    @skin_item = SkinItem.find(params[:skin_item_id])
  end

  # Responds inside the matching <turbo-frame>, swapping just the star button.
  # Falls back to a full redirect when JS/Turbo is unavailable.
  def render_star
    starred = StarredSkinItem.exists?(skin_item_id: @skin_item.id)
    respond_to do |format|
      format.html do
        render partial: "stars/star", locals: { skin_item_id: @skin_item.id, starred: starred }
      end
      format.any { redirect_back fallback_location: root_path }
    end
  end
end
