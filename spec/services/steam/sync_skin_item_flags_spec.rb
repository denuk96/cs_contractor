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
end
