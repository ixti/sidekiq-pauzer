# frozen_string_literal: true

require "forwardable"
require "concurrent"

module Sidekiq
  module Pauzer
    # @api internal
    # Eventually consistent list of paused queues. Used by Sidekiq fetchers to
    # avoid hitting Redis on every fetch call.
    class Queues
      include Enumerable

      # @param refresh_rate [Float]
      # @param repository [Repository]
      def initialize(refresh_rate, repository:)
        @names     = [].freeze
        @refresher = Concurrent::TimerTask.new(execution_interval: refresh_rate, run_now: true) do
          @names = repository.to_a.freeze
        end
      end

      # @overload each
      #   @return [Enumerator<String>]
      #
      # @overload each(&block)
      #   For a block { |queue_name| ... }
      #   @yieldparam queue_name [String]
      #   @return [self]
      def each(&block)
        return to_enum __method__ unless block

        start_refresher unless refresher_running?
        @names.each(&block)

        self
      end

      # Starts paused queues list async poller.
      #
      # @return [self]
      def start_refresher
        @refresher.execute
        self
      end

      # Stops paused queues list async poller.
      #
      # @return [self]
      def stop_refresher
        @refresher.shutdown
        self
      end

      def refresher_running?
        @refresher.running?
      end
    end
  end
end
