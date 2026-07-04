class ApplicationMailer < ActionMailer::Base
  # Gmail requires the From address to match the authenticated account, so
  # default to it (late-bound, since credentials come from ENV at runtime).
  default from: -> { ENV["MAILER_FROM"].presence || ENV["GMAIL_USERNAME"].presence || "from@example.com" }
  layout "mailer"
end
