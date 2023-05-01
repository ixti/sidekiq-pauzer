# frozen_string_literal: true

module Sidekiq
  module Pauzer
    module Adapters
      # redis-rb adapter
      module Redis
        class << self
          def adapts?(redis)
            return true if defined?(::Redis) && redis.is_a?(::Redis)
            return true if defined?(::Redis::Namespace) && redis.is_a?(::Redis::Namespace)

            false
          end

          def pause!(redis, key, queue)
            redis.sadd(key, queue)
          end

          def unpause!(redis, key, queue)
            redis.srem(key, queue)
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
