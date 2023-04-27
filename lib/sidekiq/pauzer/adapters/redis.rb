# frozen_string_literal: true

require_relative "./base"

module Sidekiq
  module Pauzer
    module Adapters
      # redis-rb adapter
      class Redis < Base
        def self.adapts?(redis)
          return true if defined?(::Redis) && redis.is_a?(::Redis)
          return true if defined?(::Redis::Namespace) && redis.is_a?(::Redis::Namespace)

          false
        end

        def pause!(queue)
          redis.sadd(redis_key, normalize(queue))
        end

        def resume!(queue)
          redis.srem(redis_key, normalize(queue))
        end

        def paused?(queue)
          redis.sismember(redis_key, normalize(queue))
        end

        def paused_queues
          # Cursor is not atomic, so there may be duplicates because of
          # concurrent update operations
          redis.sscan_each(redis_key).to_a.uniq
        end
      end
    end
  end
end
