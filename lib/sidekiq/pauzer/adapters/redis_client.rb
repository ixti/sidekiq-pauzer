# frozen_string_literal: true

require_relative "../runtime"

module Sidekiq
  module Pauzer
    module Adapters
      # redis-client adapter
      module RedisClient
        class << self
          def adapts?(redis)
            return true if Runtime::SIDEKIQ_SEVEN
            return true if defined?(::RedisClient) && redis.is_a?(::RedisClient)
            return true if defined?(::RedisClient::Decorator::Client) && redis.is_a?(::RedisClient::Decorator::Client)

            false
          end

          def add(redis, key, queue)
            redis.call("SADD", key, queue)
          end

          def remove(redis, key, queue)
            redis.call("SREM", key, queue)
          end

          def list(redis, key)
            # Cursor is not atomic, so there may be duplicates because of
            # concurrent update operations
            # See: https://redis.io/commands/scan/#scan-guarantees
            redis.sscan(key).to_a.uniq.each(&:freeze)
          end
        end
      end
    end
  end
end
