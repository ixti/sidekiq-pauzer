# frozen_string_literal: true

require_relative "./base"

module Sidekiq
  module Pauzer
    module Adapters
      # redis-client adapter
      class RedisClient < Base
        SIDEKIQ_SEVEN   = Gem::Version.new("7.0.0").freeze
        SIDEKIQ_VERSION = Gem::Version.new(Sidekiq::VERSION).freeze

        def self.adapts?(redis)
          return true if SIDEKIQ_SEVEN <= SIDEKIQ_VERSION
          return true if defined?(::RedisClient) && redis.is_a?(::RedisClient)
          return true if defined?(::RedisClient::Decorator::Client) && redis.is_a?(::RedisClient::Decorator::Client)

          false
        end

        def pause!(queue)
          redis.call("SADD", redis_key, normalize(queue))
        end

        def resume!(queue)
          redis.call("SREM", redis_key, normalize(queue))
        end

        def paused?(queue)
          redis.call("SISMEMBER", redis_key, normalize(queue)) == 1
        end

        def paused_queues
          redis.call("SMEMBERS", redis_key)
        end
      end
    end
  end
end
