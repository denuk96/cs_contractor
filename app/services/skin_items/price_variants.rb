# frozen_string_literal: true

module SkinItems
  # Collects every market variant (wear × finish) of a skin so the show page can
  # render the Normal / StatTrak™ / Souvenir price selector for one SkinItem.
  class PriceVariants
    WEAR_ORDER = SkinItem.wears.keys.freeze

    FINISHES = [
      ["normal",   "Normal",    ->(s) { !s.souvenir && !s.stattrak }],
      ["stattrak", "StatTrak™", ->(s) { s.stattrak }],
      ["souvenir", "Souvenir",  ->(s) { s.souvenir }]
    ].freeze

    Result = Data.define(:image, :wears, :rows, :current_finish)

    def initialize(skin_item)
      @skin_item = skin_item
    end

    def call
      Result.new(image:, wears:, rows:, current_finish:)
    end

    private

    attr_reader :skin_item

    def siblings
      @siblings ||= SkinItem.where(skin_id: skin_item.skin_id).have_prices.to_a
    end

    # `itemimage` from the Steam price feed lives on each SkinItem (see
    # Import::SkinItems); fall back to other priced variants if this one is blank.
    def image
      skin_item.image.presence || siblings.find { |s| s.image.present? }&.image
    end

    # Columns: only wears that actually have at least one priced variant.
    def wears
      WEAR_ORDER.select { |wear| siblings.any? { |s| s.wear == wear } }
    end

    # Rows: one per finish, skipped when the skin has no items of that finish.
    def rows
      FINISHES.filter_map do |key, label, matcher|
        items = siblings.select(&matcher)
        next if items.empty?

        { key: key, label: label, items_by_wear: items.index_by(&:wear) }
      end
    end

    # Which finish toggle should be open on load (the one being viewed).
    def current_finish
      return "souvenir" if skin_item.souvenir?
      return "stattrak" if skin_item.stattrak?

      "normal"
    end
  end
end
