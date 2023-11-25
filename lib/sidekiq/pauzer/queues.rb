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
        @config          = config
        @names           = [].freeze
        @names_mutex     = Mutex.new
        @refresher       = nil
        @refresher_mutex = Mutex.new
      end

      def each(&block)
        return to_enum __method__ unless block

        start_refresher unless refresher_running?
        @names_mutex.synchronize { @names.dup }.each(&block)

        self
      end

      # @param name [#to_s]
      # @return [Queues] self
      def pause!(name)
        redis_call("SADD", redis_key, name.to_s)
        refresh
        self
      end

      # @param name [#to_s]
      # @return [Queues] self
      def unpause!(name)
        redis_call("SREM", redis_key, name.to_s)
        refresh
        self
      end

      # @param name [#to_s]
      # @return [Boolean]
      def paused?(name)
        include?(name.to_s)
      end

      def start_refresher
        @refresher_mutex.synchronize do
          @refresher&.shutdown
          @refresher = Concurrent::TimerTask.execute(execution_interval: refresh_rate, run_now: true) { refresh }
        end

        self
      end

      def stop_refresher
        @refresher_mutex.synchronize do
          @refresher&.shutdown
          @refresher = nil
        end

        self
      end

      def refresher_running?
        @refresher_mutex.synchronize do
          @refresher&.running? || false
        end
      end

      private

      # @return [nil]
      def refresh
        names = redis_call("SMEMBERS", redis_key).to_a

        @names_mutex.synchronize do
          @names = names.each(&:freeze).freeze
        end

        nil
      end

      def redis_call(...)
        Sidekiq.redis { |conn| conn.call(...) }
      end
    end
  end
end
