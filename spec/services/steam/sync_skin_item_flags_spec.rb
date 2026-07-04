require "rails_helper"

RSpec.describe Steam::SyncSkinItemFlags do
  subject(:call) { described_class.new(catalog: catalog).call }

  let(:catalog) do
    [
      { "market_hash_name" => "AK-47 | Redline (Field-Tested)" },
      { "market_hash_name" => "StatTrak™ AK-47 | Redline (Field-Tested)" },
      { "market_hash_name" => "Operation Riptide Case" }
    ]
  end

  it "flags an item that is directly purchasable from the store" do
    skin = create(:skin, name: "AK-47 | Redline", crates: [])
    skin_item = create(:skin_item, skin: skin, name: "AK-47 | Redline (Field-Tested)")

    call

    expect(skin_item.reload.in_game_store).to be(true)
  end

  it "flags a StatTrak variant that is itself in the store catalog" do
    skin = create(:skin, name: "AK-47 | Redline", crates: [])
    skin_item = create(:skin_item, skin: skin, name: "StatTrak™ AK-47 | Redline (Field-Tested)")

    call

    expect(skin_item.reload.in_game_store).to be(true)
  end

  it "flags an item that can be unboxed from a case currently sold in-store" do
    skin = create(:skin, name: "AWP | Dragon Lore", crates: ["Operation Riptide Case"])
    skin_item = create(:skin_item, skin: skin, name: "AWP | Dragon Lore (Factory New)")

    call

    expect(skin_item.reload.in_game_store).to be(true)
  end

  it "does not flag an item that is neither purchasable nor unboxable from the store" do
    skin = create(:skin, name: "M4A4 | Howl", crates: ["Falchion Case"])
    skin_item = create(:skin_item, skin: skin, name: "M4A4 | Howl (Minimal Wear)")

    call

    expect(skin_item.reload.in_game_store).to be(false)
  end

  it "clears the flag for items that are no longer available" do
    skin = create(:skin, name: "M4A4 | Howl", crates: [])
    skin_item = create(:skin_item, skin: skin, name: "M4A4 | Howl (Minimal Wear)", in_game_store: true)

    call

    expect(skin_item.reload.in_game_store).to be(false)
  end

  describe "the result it returns" do
    it "reports items that just left the store as newly discontinued" do
      leaving = create(:skin_item, skin: create(:skin, name: "M4A4 | Howl", crates: []),
                                   name: "M4A4 | Howl (Minimal Wear)", in_game_store: true)
      create(:skin_item, skin: create(:skin, name: "AK-47 | Redline", crates: []),
                         name: "AK-47 | Redline (Field-Tested)", in_game_store: true)

      result = call

      expect(result.newly_discontinued_ids).to contain_exactly(leaving.id)
      expect(result.discontinued?).to be(true)
      expect(result.newly_listed_ids).to be_empty
    end

    it "reports items that just appeared in the store as newly listed" do
      arriving = create(:skin_item, skin: create(:skin, name: "AK-47 | Redline", crates: []),
                                    name: "AK-47 | Redline (Field-Tested)", in_game_store: false)

      result = call

      expect(result.newly_listed_ids).to contain_exactly(arriving.id)
      expect(result.listed?).to be(true)
    end
  end

  describe "safety guards against a bad catalog fetch" do
    it "aborts without touching flags when the catalog is empty" do
      skin_item = create(:skin_item, name: "AK-47 | Redline (Field-Tested)", in_game_store: true)

      expect { described_class.new(catalog: []).call }
        .to raise_error(Steam::SyncSkinItemFlags::UntrustworthyCatalogError)
      expect(skin_item.reload.in_game_store).to be(true)
    end

    it "aborts when an implausible share of in-store items would be discontinued at once" do
      shared = create(:skin, name: "Some Case Skin", crates: [])
      create_list(:skin_item, Steam::SyncSkinItemFlags::ANOMALY_MIN_BASELINE + 1,
                  skin: shared, in_game_store: true)

      expect { described_class.new(catalog: [{ "market_hash_name" => "Unrelated Case" }]).call }
        .to raise_error(Steam::SyncSkinItemFlags::UntrustworthyCatalogError, /refusing to discontinue/)
      expect(SkinItem.where(in_game_store: true).count).to eq(Steam::SyncSkinItemFlags::ANOMALY_MIN_BASELINE + 1)
    end
  end
end
