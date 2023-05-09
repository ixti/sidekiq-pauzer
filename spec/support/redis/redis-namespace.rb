# frozen_string_literal: true

require "redis"
require "redis/namespace"

require "rspec/core/shared_context"

REDIS = Redis::Namespace.new("sidekiq-pauzer", redis: Redis.new(url: REDIS_URL))

module PauzerRedisSharedContext
  extend RSpec::Core::SharedContext

  before do
    REDIS.redis.flushdb
  end

  def redis_smembers(key)
    REDIS.smembers(key)
  end

  def redis_sadd(key, value)
    REDIS.sadd(key, value)
  end
end
