# frozen_string_literal: true

require "forwardable"
require "sidekiq"
require "sidekiq/api"

require_relative "./pauzer/basic_fetch"
require_relative "./pauzer/config"
require_relative "./pauzer/queues"
require_relative "./pauzer/version"

begin
  require "sidekiq-ent/version"
  raise "sidekiq-pauzer is incompatible with Sidekiq Enterprise"
rescue LoadError
  # All good - no compatibility issues
end

begin
  require "sidekiq/pro/version"

  raise "sidekiq-pauzer is incompatible with Sidekiq Pro"
rescue LoadError
  # All good - no compatibility issues
end

module Sidekiq
  module Pauzer
    MUTEX = Mutex.new

    @config = Config.new
    @queues = Queues.new(@config)

    class << self
      extend Forwardable

      def_delegators :@queues, :pause!, :unpause!, :paused?

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

  class Queue
    remove_method :paused?

    def paused?
      Pauzer.paused?(name)
    end

    def pause!
      Pauzer.pause!(name)
    end

    def unpause!
      Pauzer.unpause!(name)
    end
  end

  configure_server do |config|
    config.on(:startup) { Pauzer.startup }
    config.on(:shutdown) { Pauzer.shutdown }
  end
end
