# frozen_string_literal: true

require "concurrent"

require_relative "./adapters"

module Sidekiq
  module Pauzer
    # @api internal
    class Queues
      include Enumerable

      class Refresher < Concurrent::TimerTask; end

      # @param config [Config]
      def initialize(config)
        @names     = Concurrent::Array.new
        @redis_key = config.redis_key
        @refresher = initialize_refresher(config.refresh_rate)
      end

      def each(&block)
        return to_enum __method__ unless block

        @names.dup.each(&block)

        self
      end

      # @param name [#to_s]
      def pause!(name)
        Sidekiq.redis { |conn| Adapters[conn].add(conn, @redis_key, name.to_s) }

        refresh
      end

      # @param name [#to_s]
      def unpause!(name)
        Sidekiq.redis { |conn| Adapters[conn].remove(conn, @redis_key, name.to_s) }

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
        Refresher.new(execution_interval: refresh_rate, run_now: true) do
          refresh
        end
      end

      def refresh
        @names.replace(Sidekiq.redis { |conn| Adapters[conn].list(conn, @redis_key) })

        self
      end
    end
  end
end
