# frozen_string_literal: true

Rails.application.configure do
  MissionControl::Jobs.http_basic_auth_user = ENV.fetch("SOLID_QUEUE_USERNAME", "dev")
  MissionControl::Jobs.http_basic_auth_password = ENV.fetch("SOLID_QUEUE_PASSWORD", "secret")
end

