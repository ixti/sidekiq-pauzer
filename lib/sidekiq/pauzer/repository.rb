# frozen_string_literal: true

module Sidekiq
  module Pauzer
    class Repository
      include Enumerable

      REDIS_KEY = "sidekiq-pauzer"

      # @overload each
      #   @return [Enumerator<String>]
      #
      # @overload each(&block)
      #   For a block { |queue_name| ... }
      #   @yieldparam queue_name [String]
      #   @return [self]
      def each
        return to_enum __method__ unless block_given?

        redis_call("SMEMBERS", REDIS_KEY).each { yield _1.freeze }

        self
      end

      # @param queue_name [#to_s]
      # @return [void]
      def add(queue_name)
        redis_call("SADD", REDIS_KEY, queue_name.to_s)
        nil
      end

      # @param queue_name [#to_s]
      # @return [void]
      def delete(queue_name)
        redis_call("SREM", REDIS_KEY, queue_name.to_s)
        nil
      end

      # @param name [#to_s]
      # @return [void]
      def include?(queue_name)
        redis_call("SISMEMBER", REDIS_KEY, queue_name.to_s).positive?
      end

      private

      def redis_call(...)
        Sidekiq.redis { _1.call(...) }
      end
    end
  end
end
