# frozen_string_literal: true

require "sidekiq"
require "sidekiq/api"

begin
  # :nocov:
  require "sidekiq-ent/version"
  raise "sidekiq-pauzer is incompatible with Sidekiq Enterprise"
  # :nocov:
rescue LoadError
  # All good - no compatibility issues
end

begin
  # :nocov:
  require "sidekiq/pro/version"
  raise "sidekiq-pauzer is incompatible with Sidekiq Pro"
  # :nocov:
rescue LoadError
  # All good - no compatibility issues
end

require_relative "./pauzer/config"
require_relative "./pauzer/patches/basic_fetch"
require_relative "./pauzer/patches/queue"
require_relative "./pauzer/queues"
require_relative "./pauzer/repository"
require_relative "./pauzer/version"

module Sidekiq
  module Pauzer
    MUTEX = Mutex.new
    private_constant :MUTEX

    @config     = Config.new.freeze
    @repository = Repository.new
    @queues     = Queues.new(@config.refresh_rate, repository: @repository)

    class << self
      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused?("minor") # => true
      #
      # @param (see Repository#add)
      # @return [void]
      def pause!(queue_name)
        @repository.add(queue_name)
        nil
      end

      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused?("minor") # => true
      #   Sidekiq::Pauzer.unpause!("minor")
      #   Sidekiq::Pauzer.paused?("minor") # => false
      #
      # @param (see Repository#delete)
      # @return [void]
      def unpause!(queue_name)
        @repository.delete(queue_name)
        nil
      end

      # @example
      #   Sidekiq::Pauzer.pause!("minor")
      #   Sidekiq::Pauzer.paused?("minor")  # => true
      #   Sidekiq::Pauzer.paused?("threat") # => false
      #
      # @return (see Repository#include?)
      def paused?(queue_name)
        @repository.include?(queue_name)
      end

      # Eventually consistent list of paused queues.
      #
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
        MUTEX.synchronize { reinit_queues.start_refresher }

        self
      end

      def shutdown
        MUTEX.synchronize { @queues.stop_refresher }

        self
      end

      private

      def reinit_queues
        @queues.stop_refresher
        @queues = Queues.new(@config.refresh_rate, repository: @repository)
      end
    end
  end

  configure_server do |config|
    config.on(:startup)  { Pauzer.startup }
    config.on(:shutdown) { Pauzer.shutdown }
  end
end
