# frozen_string_literal: true

require "forwardable"
require "sidekiq"
require "sidekiq/api"

require_relative "./pauzer/config"
require_relative "./pauzer/patches/basic_fetch"
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

      # @!attribute [r] redis_key
      #   @see Config#redis_key
      #   @return [String]
      def_delegators :@config, :redis_key

      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused?("minor") # => true
      #
      # @param (see Queues#pause!)
      # @return [void]
      def pause!(name)
        @queues.pause!(name)

        nil
      end

      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused?("minor") # => true
      #   Sidekiq::Pauzer.unpause!("minor")
      #   Sidekiq::Pauzer.paused?("minor") # => false
      #
      # @param (see Queues#unpause!)
      # @return [void]
      def unpause!(name)
        @queues.unpause!(name)

        nil
      end

      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused?("minor")  # => true
      #   Sidekiq::Pauzer.paused?("threat") # => false
      #
      # @see Queues#paused?
      def paused?(name)
        @queues.paused?(name)
      end

      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused_queues # => ["minor"]
      #
      # @return [Array<String>]
      def paused_queues
        @queues.to_a
      end

      # Yields `config` for a block.
      #
      # @example
      #   Sidekiq::Pauzer.configure do |config|
      #     config.refresh_rate = 42
      #   end
      #
      # @yieldparam config [Config]
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
