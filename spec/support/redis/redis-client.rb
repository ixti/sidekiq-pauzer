# frozen_string_literal: true

require "redis_client"

require "rspec/core/shared_context"

REDIS = RedisClient.new(url: REDIS_URL)

module PauzerRedisSharedContext
  extend RSpec::Core::SharedContext

  before do
    REDIS.call("FLUSHDB")
  end

  def redis_smembers(key)
    REDIS.call("SMEMBERS", key)
  end

  def redis_sadd(key, value)
    REDIS.call("SADD", key, value)
  end
end
