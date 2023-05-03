# frozen_string_literal: true

require "concurrent"

require_relative "./adapters"

module Sidekiq
  module Pauzer
    # @api internal
    class Queues
      include Enumerable

      class Refresher < Concurrent::TimerTask; end

      QUEUE_PREFIX = "queue:"

      # @param config [Config]
      def initialize(config)
        @mutex     = Mutex.new
        @queues    = []
        @redis_key = config.redis_key
        @refresher = initialize_refresher(config.refresh_rate)
      end

      def each(&block)
        return to_enum __method__ unless block

        @mutex.synchronize { @queues.dup }.each(&block)

        self
      end

      def pause!(queue)
        queue = normalize_queue_name(queue)

        Sidekiq.redis { |conn| Adapters[conn].pause!(conn, @redis_key, queue) }

        refresh
      end

      def unpause!(queue)
        queue = normalize_queue_name(queue)

        Sidekiq.redis { |conn| Adapters[conn].unpause!(conn, @redis_key, queue) }

        refresh
      end

      def paused?(queue)
        include?(normalize_queue_name(queue))
      end

      def start_refresher
        @refresher.execute
        nil
      end

      def stop_refresher
        @refresher.shutdown
        nil
      end

      def refresher_running?
        @refresher.running?
      end

      private

      def initialize_refresher(refresh_rate)
        Refresher.new(execution_interval: refresh_rate, run_now: true) do
          refresh
        end
      end

      def refresh
        @mutex.synchronize do
          paused_queues = Sidekiq.redis do |conn|
            Adapters[conn].paused_queues(conn, @redis_key)
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
