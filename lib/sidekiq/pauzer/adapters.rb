# frozen_string_literal: true

require_relative "./adapters/redis"
require_relative "./adapters/redis_client"

module Sidekiq
  module Pauzer
    # @api internal
    module Adapters
      class << self
        def build(redis, config)
          return Adapters::RedisClient.new(redis, config) if Adapters::RedisClient.adapts?(redis)
          return Adapters::Redis.new(redis, config)       if Adapters::Redis.adapts?(redis)

          raise TypeError, "Unsupported redis client: #{redis.class}"
        end
      end
    end
  end
end
