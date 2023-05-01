# frozen_string_literal: true

require_relative "./adapters/redis"
require_relative "./adapters/redis_client"

module Sidekiq
  module Pauzer
    # @api internal
    module Adapters
      def self.[](redis)
        return Adapters::RedisClient if Adapters::RedisClient.adapts?(redis)
        return Adapters::Redis       if Adapters::Redis.adapts?(redis)

        raise TypeError, "Unsupported redis client: #{redis.class}"
      end
    end
  end
end
