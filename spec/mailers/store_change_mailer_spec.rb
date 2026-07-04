require "rails_helper"

RSpec.describe StoreChangeMailer, type: :mailer do
  describe "#discontinued" do
    let(:skin) { create(:skin, name: "AWP | Dragon Lore", crates: ["Operation Riptide Case"]) }
    let!(:item) do
      create(:skin_item, skin: skin, name: "AWP | Dragon Lore (Factory New)",
                         rarity: "Covert", latest_steam_price: 12_345.67)
    end

    around do |example|
      original = ENV["NOTIFY_EMAIL"]
      ENV["NOTIFY_EMAIL"] = "alerts@example.com"
      example.run
      ENV["NOTIFY_EMAIL"] = original
    end

    it "addresses a subject-lined alert to the notify recipient" do
      mail = described_class.discontinued([item.id])

      expect(mail.to).to eq(["alerts@example.com"])
      expect(mail.subject).to eq("CS2 store: 1 item discontinued")
    end

    it "pluralizes the subject for multiple items" do
      other = create(:skin_item, skin: create(:skin, name: "AK-47 | Case Hardened", crates: []),
                                 name: "AK-47 | Case Hardened (Field-Tested)")

      mail = described_class.discontinued([item.id, other.id])

      expect(mail.subject).to eq("CS2 store: 2 items discontinued")
    end

    it "lists each item with its source case and price" do
      body = described_class.discontinued([item.id]).body.encoded

      expect(body).to include("AWP | Dragon Lore (Factory New)")
      expect(body).to include("Operation Riptide Case")
      expect(body).to include("12345.67")
    end

    it "renders nothing when no items match" do
      mail = described_class.discontinued([])

      expect(mail.to).to be_nil
      expect(mail.subject).to be_nil
    end
  end
end
