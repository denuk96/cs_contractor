class SyncSteamStoreFlagsJob < ApplicationJob
  queue_as :default

  def perform
    result = Steam::SyncSkinItemFlags.new.call

    if result.listed?
      Rails.logger.info("[SyncSteamStoreFlags] #{result.newly_listed_ids.size} item(s) newly listed in store")
    end

    notify_discontinued(result.newly_discontinued_ids)
  end

  private

  # Best-effort notification: the flag sync has already succeeded by this
  # point, so a mail misconfiguration must only be logged, never re-raised
  # (otherwise it would mark this recurring job as failed every run).
  def notify_discontinued(ids)
    return if ids.blank?

    unless smtp_configured?
      Rails.logger.warn(
        "[SyncSteamStoreFlags] #{ids.size} item(s) discontinued but email skipped: " \
        "SMTP not configured (set GMAIL_USERNAME / GMAIL_APP_PASSWORD)"
      )
      return
    end

    StoreChangeMailer.discontinued(ids).deliver_now
    Rails.logger.info("[SyncSteamStoreFlags] emailed alert for #{ids.size} discontinued item(s)")
  rescue => e
    Rails.logger.error("[SyncSteamStoreFlags] failed to send discontinued-items email: #{e.class}: #{e.message}")
  end

  def smtp_configured?
    ActionMailer::Base.delivery_method == :smtp &&
      ActionMailer::Base.smtp_settings[:password].present?
  end
end
