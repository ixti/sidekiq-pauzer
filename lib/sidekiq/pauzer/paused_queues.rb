# frozen_string_literal: true

require_relative "./adapters"

module Sidekiq
  module Pauzer
    # @api internal
    class PausedQueues
      include Enumerable
      include Sidekiq::Component

      QUEUE_PREFIX = "queue:"
      private_constant :QUEUE_PREFIX

      def initialize(config)
        @mutex  = Mutex.new
        @queues = []
        @config = config
      end

      def to_a
        @mutex.synchronize { @queues.dup }
      end

      def each(&block)
        return to_enum __method__ unless block

        to_a.each(&block)

        self
      end

      def pause!(queue)
        queue = normalize_queue_name(queue)

        redis { |conn| Adapters[conn].pause!(conn, @config.redis_key, queue) }

        refresh
      end

      def resume!(queue)
        queue = normalize_queue_name(queue)

        redis { |conn| Adapters[conn].resume!(conn, @config.redis_key, queue) }

        refresh
      end

      def paused?(queue)
        include?(normalize_queue_name(queue))
      end

      private

      def refresh
        @mutex.synchronize do
          paused_queues = redis do |conn|
            Adapters[conn].paused_queues(conn, @config.redis_key)
          end

          @queues.replace(paused_queues)
        end

        self
      end

      def normalize_queue_name(queue)
        queue.dup.delete_prefix(QUEUE_PREFIX)
      end
    end
  end
end
