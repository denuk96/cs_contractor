class JobErrorMailer < ApplicationMailer
  # Alerts that a recurring background job raised an unhandled error. Without
  # this, a scheduled run just gets marked failed in Solid Queue where nobody
  # looks. Sent from NotifiesOnFailure.
  def failed(job_name, error)
    @job_name    = job_name
    @error       = error
    @backtrace   = Array(error.backtrace).first(15)
    @occurred_at = Time.current

    mail(
      to: notify_address,
      subject: "cs_contractor job failed: #{job_name} (#{error.class})"
    )
  end

  private

  def notify_address
    ENV["NOTIFY_EMAIL"].presence || ENV["GMAIL_USERNAME"]
  end
end
