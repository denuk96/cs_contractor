# == Schema Information
#
# Table name: starred_skin_items
#
#  id           :integer          not null, primary key
#  skin_item_id :integer          not null
#  user_id      :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_starred_skin_items_on_skin_item_id              (skin_item_id)
#  index_starred_skin_items_on_user_id_and_skin_item_id  (user_id,skin_item_id) UNIQUE
#

class StarredSkinItem < ApplicationRecord
  belongs_to :skin_item
  # No User model yet. Once one exists, enable per-user stars:
  #   belongs_to :user, optional: true
end
