module Steam
  # Flags SkinItems that are currently obtainable from the CS2 in-game
  # store: either bought directly, or unboxed from a case/capsule that
  # Valve currently sells there.
  #
  # Returns a Result describing which items changed availability this run, so
  # callers can react to items that just left the store (i.e. were
  # discontinued) or just appeared in it.
  class SyncSkinItemFlags
    # Raised when the fetched store catalog is empty or implausibly small.
    # That almost always means a Steam API failure rather than Valve actually
    # emptying the store, so we abort instead of wiping every `in_game_store`
    # flag (which would also fire a bogus "everything discontinued" alert).
    class UntrustworthyCatalogError < StandardError; end

    # Once we have a meaningful baseline of in-store items, we never expect
    # more than this fraction of them to vanish in a single 6-hourly sync. A
    # larger drop is treated as a bad fetch and aborts the run.
    ANOMALY_FRACTION = 0.5
    ANOMALY_MIN_BASELINE = 50

    Result = Data.define(:newly_discontinued_ids, :newly_listed_ids) do
      def discontinued? = newly_discontinued_ids.any?
      def listed? = newly_listed_ids.any?
    end

    def initialize(catalog: nil)
      @catalog = catalog
    end

    def call
      raise UntrustworthyCatalogError, "store catalog is empty" if store_names.empty?

      available_ids = SkinItem.includes(:skin).find_each.filter_map do |skin_item|
        skin_item.id if available_in_store?(skin_item)
      end

      # Snapshot transitions before overwriting, so we know exactly which
      # items just left the store (were flagged, no longer available) and
      # which just entered it (weren't flagged, now available).
      newly_discontinued_ids = SkinItem.where(in_game_store: true).where.not(id: available_ids).pluck(:id)
      newly_listed_ids = SkinItem.where(in_game_store: false, id: available_ids).pluck(:id)

      guard_against_mass_discontinuation!(newly_discontinued_ids)

      ActiveRecord::Base.transaction do
        SkinItem.where(id: available_ids).update_all(in_game_store: true)
        SkinItem.where.not(id: available_ids).update_all(in_game_store: false)
      end

      Result.new(newly_discontinued_ids:, newly_listed_ids:)
    end

    private

    def guard_against_mass_discontinuation!(newly_discontinued_ids)
      baseline = SkinItem.where(in_game_store: true).count
      return if baseline < ANOMALY_MIN_BASELINE
      return if newly_discontinued_ids.size <= baseline * ANOMALY_FRACTION

      raise UntrustworthyCatalogError,
            "refusing to discontinue #{newly_discontinued_ids.size} of #{baseline} in-store items in one sync"
    end

    def available_in_store?(skin_item)
      return true if store_names.include?(skin_item.name)

      Array(skin_item.skin&.crates).any? { |crate_name| store_names.include?(crate_name) }
    end

    def store_names
      @store_names ||= (@catalog || FetchStoreCatalog.new.call).filter_map { |item| item["market_hash_name"] }.to_set
    end
  end
end
