require "rails_helper"

RSpec.describe SyncSteamStoreFlagsJob do
  let(:service) { instance_double(Steam::SyncSkinItemFlags, call: result) }
  let(:result) do
    Steam::SyncSkinItemFlags::Result.new(newly_discontinued_ids: [1, 2], newly_listed_ids: [])
  end

  before { allow(Steam::SyncSkinItemFlags).to receive(:new).and_return(service) }

  context "when items were discontinued and SMTP is configured" do
    before do
      allow(ActionMailer::Base).to receive(:delivery_method).and_return(:smtp)
      allow(ActionMailer::Base).to receive(:smtp_settings).and_return(password: "app-password")
    end

    it "emails an alert for the discontinued items" do
      message = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      expect(StoreChangeMailer).to receive(:discontinued).with([1, 2]).and_return(message)

      described_class.perform_now
    end

    it "never lets a mail failure escape the job" do
      allow(StoreChangeMailer).to receive(:discontinued).and_raise(StandardError.new("smtp down"))

      expect { described_class.perform_now }.not_to raise_error
    end
  end

  context "when SMTP is not configured" do
    it "skips sending without raising" do
      expect(StoreChangeMailer).not_to receive(:discontinued)
      expect { described_class.perform_now }.not_to raise_error
    end
  end

  context "when nothing was discontinued" do
    let(:result) do
      Steam::SyncSkinItemFlags::Result.new(newly_discontinued_ids: [], newly_listed_ids: [3])
    end

    it "does not send an email" do
      expect(StoreChangeMailer).not_to receive(:discontinued)
      described_class.perform_now
    end
  end
end
