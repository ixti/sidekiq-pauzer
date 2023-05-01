# frozen_string_literal: true

require "forwardable"
require "sidekiq"

require_relative "./sidekiq/pauzer/basic_fetch"
require_relative "./sidekiq/pauzer/config"
require_relative "./sidekiq/pauzer/queues"
require_relative "./sidekiq/pauzer/version"

module Sidekiq
  module Pauzer
    MUTEX = Mutex.new

    @config = Config.new
    @queues = Queues.new(@config)

    class << self
      extend Forwardable

      def_delegators :@queues, :pause!, :resume!, :paused?

      def paused_queues
        @queues.map { |queue| "#{Queues::QUEUE_PREFIX}#{queue}" }
      end

      def configure
        MUTEX.synchronize do
          yield @config
        ensure
          start_refresher = @queues.refresher_running?
          @queues.stop_refresher
          @queues = Queues.new(@config)
          @queues.start_refresher if start_refresher
        end
      end

      def startup
        MUTEX.synchronize { @queues.start_refresher }
      end

      def shutdown
        MUTEX.synchronize { @queues.stop_refresher }
      end
    end
  end

  configure_server do |config|
    config.on(:startup) { Pauzer.startup }
    config.on(:shutdown) { Pauzer.shutdown }
  end
end
