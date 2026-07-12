# Included in the recurring background jobs (config/recurring.yml) so an
# unhandled error also emails an alert — otherwise a failed scheduled run is
# only recorded in Solid Queue, where nobody looks. The original error is
# re-raised after the email so the run is still marked failed (and any retry
# logic still applies); the mail is a side channel, never a replacement.
module NotifiesOnFailure
  extend ActiveSupport::Concern

  included do
    rescue_from(StandardError) do |error|
      notify_job_failure(error)
      raise error
    end
  end

  private

  # Best-effort: a mail misconfiguration must never mask the job's real error,
  # so any failure here is logged rather than re-raised over the original.
  def notify_job_failure(error)
    unless smtp_configured?
      Rails.logger.warn(
        "[#{self.class.name}] failed (#{error.class}) but alert email skipped: " \
        "SMTP not configured (set GMAIL_USERNAME / GMAIL_APP_PASSWORD)"
      )
      return
    end

    JobErrorMailer.failed(self.class.name, error).deliver_now
    Rails.logger.info("[#{self.class.name}] emailed failure alert (#{error.class})")
  rescue => mailer_error
    Rails.logger.error(
      "[#{self.class.name}] failed to send failure-alert email: " \
      "#{mailer_error.class}: #{mailer_error.message}"
    )
  end

  def smtp_configured?
    ActionMailer::Base.delivery_method == :smtp &&
      ActionMailer::Base.smtp_settings[:password].present?
  end
end
