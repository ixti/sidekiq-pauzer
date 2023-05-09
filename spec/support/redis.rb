# frozen_string_literal: true

REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379")
REDIS_GEM = ENV.fetch("REDIS_GEM", "redis")

begin
  require_relative "./redis/#{REDIS_GEM}"
rescue LoadError
  raise "Invalid REDIS_GEM"
end

RSpec.configure do |config|
  config.include(PauzerRedisSharedContext)
end
