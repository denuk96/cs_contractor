# Outbound mail via Gmail SMTP (used by the store-discontinued alerts).
#
# Applies to every environment except test — which keeps the :test delivery
# method so specs never hit the network. Credentials come from ENV (loaded
# from .env locally via dotenv, or from Kamal secrets in a real deploy):
#
#   GMAIL_USERNAME      your.address@gmail.com  (also the From address)
#   GMAIL_APP_PASSWORD  16-char Google App Password (NOT your login password)
#   NOTIFY_EMAIL        (optional) where alerts go; defaults to GMAIL_USERNAME
#
# raise_delivery_errors is on so a bad/missing password surfaces as a real
# Net::SMTPAuthenticationError instead of a silent "Delivered mail" log line.
ActiveSupport.on_load(:action_mailer) do
  next if Rails.env.test?

  self.delivery_method = :smtp
  self.perform_deliveries = true
  self.raise_delivery_errors = true
  self.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: ENV.fetch("SMTP_DOMAIN", "gmail.com"),
    user_name: ENV["GMAIL_USERNAME"],
    password: ENV["GMAIL_APP_PASSWORD"],
    authentication: :login,
    enable_starttls_auto: true
  }
end
