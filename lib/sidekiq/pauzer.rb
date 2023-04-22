# frozen_string_literal: true

require "sidekiq/pauzer/adapters"
require "sidekiq/pauzer/basic_fetch"
require "sidekiq/pauzer/config"
require "sidekiq/pauzer/version"

module Sidekiq
  module Pauzer
    extend Sidekiq::Component

    @config = Config.new

    class << self
      def configure
        yield @config
      end

      def pause!(queue)
        redis { |conn| Adapters.build(conn, config).pause!(queue) }
      end

      def resume!(queue)
        redis { |conn| Adapters.build(conn, config).resume!(queue) }
      end

      def paused?(queue)
        redis { |conn| Adapters.build(conn, config).paused?(queue) }
      end

      def paused_queues
        redis { |conn| Adapters.build(conn, config).paused_queues }
      end
    end
  end
end
