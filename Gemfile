# frozen_string_literal: true

source "https://rubygems.org"

gem "appraisal"
gem "rake"

group :test do
  gem "redis"
  gem "redis-client"
  gem "redis-namespace"
  gem "sidekiq"

  gem "capybara"
  gem "rack-test"

  gem "rspec"
  gem "rspec-parameterized"
  gem "simplecov"

  gem "rubocop", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
end

group :development, optional: true do
  gem "debug"

  gem "guard"
  gem "guard-rspec"
end

group :doc, optional: true do
  gem "asciidoctor"
  gem "yard"
end

gemspec
