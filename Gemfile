source "https://rubygems.org"

# Rails core
gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Frontend
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Solid stack (Rails 8 default backends)
gem "solid_cache"
gem "solid_queue"

# Auth
gem "devise", "~> 4.9"
gem "pundit", "~> 2.4"

# Domain
gem "money-rails", "~> 1.15"
gem "discard", "~> 1.4"
gem "audited", "~> 5.7"

# Utilities
gem "bootsnap", require: false
gem "image_processing", "~> 2.1"
gem "kamal", require: false
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "mocha"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
