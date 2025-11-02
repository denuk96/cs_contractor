source "https://rubygems.org"

ruby "3.4.7"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "importmap-rails"
gem "jbuilder"
gem "propshaft"
gem "puma", ">= 5.0"
gem "rails", "~> 8.1.1"
gem "sqlite3", ">= 2.1"
gem "stimulus-rails"
gem "turbo-rails"

gem "faraday"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "database_cleaner"
  gem 'database_cleaner-active_record'
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv"
  gem "factory_bot_rails"
  gem "factory_bot_rails"
  gem "ffaker"
  gem "rspec-rails"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "shoulda-matchers", "~> 7.0"
end

group :development do
  gem "ffaker"
  gem "web-console"
  gem "webdrivers"
  gem "webmock"
end
