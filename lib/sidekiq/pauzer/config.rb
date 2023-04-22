# frozen_string_literal: true

module Sidekiq
  module Pauzer
    class Config
      REDIS_KEY = "pauzer"

      # @return [String?]
      attr_reader :key_prefix

      # Fully qualified Redis key
      #
      # @example With key prefix
      #   config.key_prefix = "foobar:"
      #   config.redis_key # => "foobar:pauzer"
      #
      # @example Without key prefix (default)
      #   config.redis_key # => "pauzer"
      #
      # @return [String]
      attr_reader :redis_key

      def initialize
        @key_prefix = nil
        @redis_key  = REDIS_KEY
      end

      # Set redis key prefix
      #
      # @see redis_key
      # @param value [String?] String that should be prepended to redis key
      # @return [void]
      def key_prefix=(value)
        unless value.is_a?(String) || value.nil?
          raise ArgumentError, "expected String, or nil; got #{value.class}"
        end

        @redis_key = [value, REDIS_KEY].compact.join.freeze
        @key_prefix = value
      end
    end
  end
end
