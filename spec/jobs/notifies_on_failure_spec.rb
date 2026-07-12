require "rails_helper"

RSpec.describe NotifiesOnFailure do
  # A minimal recurring-style job that always fails, to exercise the shared
  # failure-alert hook without depending on any real job's collaborators.
  before do
    stub_const("FailingRecurringJob", Class.new(ApplicationJob) do
      include NotifiesOnFailure
      def perform = raise(StandardError, "boom")
    end)
  end

  context "when SMTP is configured" do
    before do
      allow(ActionMailer::Base).to receive(:delivery_method).and_return(:smtp)
      allow(ActionMailer::Base).to receive(:smtp_settings).and_return(password: "app-password")
    end

    it "emails a failure alert and still re-raises the original error" do
      message = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      expect(JobErrorMailer).to receive(:failed)
        .with("FailingRecurringJob", instance_of(StandardError))
        .and_return(message)

      expect { FailingRecurringJob.perform_now }.to raise_error(StandardError, "boom")
    end

    it "re-raises the original error even when sending the alert fails" do
      allow(JobErrorMailer).to receive(:failed).and_raise(StandardError.new("smtp down"))

      expect { FailingRecurringJob.perform_now }.to raise_error(StandardError, "boom")
    end
  end

  context "when SMTP is not configured" do
    it "skips the email but still re-raises the original error" do
      expect(JobErrorMailer).not_to receive(:failed)

      expect { FailingRecurringJob.perform_now }.to raise_error(StandardError, "boom")
    end
  end
end
