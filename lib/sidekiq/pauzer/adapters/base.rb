# frozen_string_literal: true

module Sidekiq
  module Pauzer
    module Adapters
      class Base
        QUEUE_PREFIX = "queue:"
        private_constant :QUEUE_PREFIX

        def initialize(redis, config)
          @redis     = redis
          @redis_key = config.redis_key
        end

        private

        attr_reader :redis, :redis_key

        def normalize(queue)
          queue.delete_prefix(QUEUE_PREFIX)
        end
      end
    end
  end
end
