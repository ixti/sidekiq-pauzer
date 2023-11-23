# frozen_string_literal: true

require "concurrent"

module Sidekiq
  module Pauzer
    # @api internal
    class Queues
      include Enumerable

      # @param config [Config]
      def initialize(config)
        @mutex     = Mutex.new
        @names     = [].freeze
        @redis_key = config.redis_key
        @refresher = initialize_refresher(config.refresh_rate)
      end

      def each(&block)
        return to_enum __method__ unless block

        start_refresher unless refresher_running?
        @names.each(&block)

        self
      end

      # @param name [#to_s]
      def pause!(name)
        Sidekiq.redis { |conn| conn.call("SADD", @redis_key, name.to_s) }
        refresh
      end

      # @param name [#to_s]
      def unpause!(name)
        Sidekiq.redis { |conn| conn.call("SREM", @redis_key, name.to_s) }
        refresh
      end

      # @param name [#to_s]
      # @return [Boolean]
      def paused?(name)
        include?(name.to_s)
      end

      def start_refresher
        @refresher.execute

        self
      end

      def stop_refresher
        @refresher.shutdown

        self
      end

      def refresher_running?
        @refresher.running?
      end

      private

      def initialize_refresher(refresh_rate)
        Concurrent::TimerTask.new(execution_interval: refresh_rate, run_now: true) do
          refresh
        end
      end

      def refresh
        names = Sidekiq.redis { |conn| conn.call("SMEMBERS", @redis_key).to_a }

        @mutex.synchronize { @names = names.each(&:freeze).freeze }

        self
      end
    end
  end
end
