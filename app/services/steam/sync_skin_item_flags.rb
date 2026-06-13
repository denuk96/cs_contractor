module Steam
  # Flags SkinItems that are currently obtainable from the CS2 in-game
  # store: either bought directly, or unboxed from a case/capsule that
  # Valve currently sells there.
  class SyncSkinItemFlags
    def initialize(catalog: nil)
      @catalog = catalog
    end

    def call
      available_ids = SkinItem.includes(:skin).find_each.filter_map do |skin_item|
        skin_item.id if available_in_store?(skin_item)
      end

      ActiveRecord::Base.transaction do
        SkinItem.where(id: available_ids).update_all(in_game_store: true)
        SkinItem.where.not(id: available_ids).update_all(in_game_store: false)
      end
    end

    private

    def available_in_store?(skin_item)
      return true if store_names.include?(skin_item.name)

      Array(skin_item.skin&.crates).any? { |crate_name| store_names.include?(crate_name) }
    end

    def store_names
      @store_names ||= (@catalog || FetchStoreCatalog.new.call).filter_map { |item| item["market_hash_name"] }.to_set
    end
  end
end
