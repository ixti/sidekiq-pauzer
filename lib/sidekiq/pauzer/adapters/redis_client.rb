# frozen_string_literal: true

module Sidekiq
  module Pauzer
    module Adapters
      # redis-client adapter
      module RedisClient
        SIDEKIQ_SEVEN   = Gem::Version.new("7.0.0").freeze
        SIDEKIQ_VERSION = Gem::Version.new(Sidekiq::VERSION).freeze

        class << self
          def adapts?(redis)
            return true if SIDEKIQ_SEVEN <= SIDEKIQ_VERSION
            return true if defined?(::RedisClient) && redis.is_a?(::RedisClient)
            return true if defined?(::RedisClient::Decorator::Client) && redis.is_a?(::RedisClient::Decorator::Client)

            false
          end

          def pause!(redis, key, queue)
            redis.call("SADD", key, queue)
          end

          def resume!(redis, key, queue)
            redis.call("SREM", key, queue)
          end

          def paused_queues(redis, key)
            # Cursor is not atomic, so there may be duplicates because of
            # concurrent update operations
            # See: https://redis.io/commands/scan/#scan-guarantees
            redis.sscan_each(key).to_a.uniq.each(&:freeze)
          end
        end
      end
    end
  end
end
