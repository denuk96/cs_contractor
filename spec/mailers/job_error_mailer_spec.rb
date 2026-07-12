require "rails_helper"

RSpec.describe JobErrorMailer, type: :mailer do
  describe "#failed" do
    let(:error) do
      StandardError.new("Steam API returned 503").tap do |e|
        e.set_backtrace(["app/services/steam/sync_skin_item_flags.rb:12:in `call'"])
      end
    end

    around do |example|
      original = ENV["NOTIFY_EMAIL"]
      ENV["NOTIFY_EMAIL"] = "alerts@example.com"
      example.run
      ENV["NOTIFY_EMAIL"] = original
    end

    it "addresses a subject-lined alert naming the job and error class" do
      mail = described_class.failed("ImportPricesJob", error)

      expect(mail.to).to eq(["alerts@example.com"])
      expect(mail.subject).to eq("cs_contractor job failed: ImportPricesJob (StandardError)")
    end

    it "includes the error message and backtrace in the body" do
      body = described_class.failed("ImportPricesJob", error).body.encoded

      expect(body).to include("ImportPricesJob")
      expect(body).to include("Steam API returned 503")
      expect(body).to include("app/services/steam/sync_skin_item_flags.rb:12")
    end

    it "renders even when the error has no backtrace" do
      mail = described_class.failed("GenerateFeedJob", StandardError.new("boom"))

      expect(mail.body.encoded).to include("boom")
    end
  end
end
