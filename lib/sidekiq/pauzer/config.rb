# frozen_string_literal: true

module Sidekiq
  module Pauzer
    class Config
      REDIS_KEY = "sidekiq-pauzer"
      private_constant :REDIS_KEY

      # Default refresh rate
      REFRESH_RATE = 10

      # @return [String?]
      attr_reader :key_prefix

      # @return [Integer, Float]
      attr_reader :refresh_rate

      # Fully qualified Redis key
      #
      # @example Without key prefix (default)
      #   config.redis_key # => "sidekiq-pauzer"
      #
      # @example With key prefix
      #   config.key_prefix = "foobar:"
      #   config.redis_key # => "foobar:sidekiq-pauzer"
      #
      # @return [String]
      attr_reader :redis_key

      def initialize
        @key_prefix   = nil
        @redis_key    = REDIS_KEY
        @refresh_rate = REFRESH_RATE
      end

      # Set redis key prefix.
      #
      # @see redis_key
      # @param value [String?] String that should be prepended to redis key
      # @return [void]
      def key_prefix=(value)
        raise ArgumentError, "expected String, or nil; got #{value.class}" unless value.is_a?(String) || value.nil?

        @redis_key  = [value, REDIS_KEY].compact.join.freeze
        @key_prefix = value&.then(&:-@) # Don't freeze original String value if it was unfrozen
      end

      # Set paused queues local cache refresh rate in seconds.
      #
      # @param value [Float, Integer] refresh interval in seconds
      # @return [void]
      def refresh_rate=(value)
        unless value.is_a?(Integer) || value.is_a?(Float)
          raise ArgumentError, "expected Integer, or Float; got #{value.class}"
        end

        raise ArgumentError, "expected positive value; got #{value.inspect}" unless value.positive?

        @refresh_rate = value
      end
    end
  end
end
