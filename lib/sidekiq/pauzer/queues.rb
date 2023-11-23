# frozen_string_literal: true

require "forwardable"
require "concurrent"

module Sidekiq
  module Pauzer
    # @api internal
    class Queues
      extend Forwardable
      include Enumerable

      # @!attribute [r] redis_key
      #   @see (Config#redis_key)
      def_delegators :@config, :redis_key

      # @!attribute [r] refresh_rate
      #   @see (Config#refresh_rate)
      def_delegators :@config, :refresh_rate

      # @param config [Config]
      def initialize(config)
        @names      = [].freeze
        @config     = config
        @init_mutex = Mutex.new
        @poll_mutex = Mutex.new
        @refresher  = nil
      end

      def each(&block)
        return to_enum __method__ unless block

        start_refresher unless refresher_running?
        @poll_mutex.synchronize { @names.dup }.each(&block)

        self
      end

      # @param name [#to_s]
      def pause!(name)
        Sidekiq.redis { |conn| conn.call("SADD", redis_key, name.to_s) }
        refresh
      end

      # @param name [#to_s]
      def unpause!(name)
        Sidekiq.redis { |conn| conn.call("SREM", redis_key, name.to_s) }
        refresh
      end

      # @param name [#to_s]
      # @return [Boolean]
      def paused?(name)
        include?(name.to_s)
      end

      def start_refresher
        @init_mutex.synchronize do
          @refresher ||= Concurrent::TimerTask.new(execution_interval: refresh_rate, run_now: true) do
            refresh
          end

          @refresher.execute
        end

        self
      end

      def stop_refresher
        @init_mutex.synchronize do
          @refresher&.shutdown
          @refresher = nil
        end

        self
      end

      def refresher_running?
        @init_mutex.synchronize { @refresher&.running? || false }
      end

      private

      def refresh
        names = Sidekiq.redis { |conn| conn.call("SMEMBERS", redis_key).to_a }

        @poll_mutex.synchronize { @names = names.each(&:freeze).freeze }

        self
      end
    end
  end
end
