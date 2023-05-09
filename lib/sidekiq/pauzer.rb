# frozen_string_literal: true

require "forwardable"
require "sidekiq"
require "sidekiq/api"

require_relative "./pauzer/basic_fetch"
require_relative "./pauzer/config"
require_relative "./pauzer/patches/queue"
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

    @config = Config.new.freeze
    @queues = Queues.new(@config)

    class << self
      extend Forwardable

      def_delegators :@queues, :pause!, :unpause!, :paused?
      def_delegators :@config, :redis_key

      def paused_queues
        @queues.map { |queue| "#{Queues::QUEUE_PREFIX}#{queue}" }
      end

      def configure
        MUTEX.synchronize do
          config = @config.dup

          yield config

          @config = config.freeze

          self
        ensure
          reinit_queues
        end
      end

      def startup
        MUTEX.synchronize { @queues.start_refresher }

        self
      end

      def shutdown
        MUTEX.synchronize { @queues.stop_refresher }

        self
      end

      private

      def reinit_queues
        start_refresher = @queues.refresher_running?
        @queues.stop_refresher
        @queues = Queues.new(@config)
        @queues.start_refresher if start_refresher
      end
    end
  end

  configure_server do |config|
    config.on(:startup)  { Pauzer.startup }
    config.on(:shutdown) { Pauzer.shutdown }
  end
end

Sidekiq::Pauzer::Patches::Queue.apply!
