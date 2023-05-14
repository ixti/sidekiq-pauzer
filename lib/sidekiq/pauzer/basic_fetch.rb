# frozen_string_literal: true

require "sidekiq"
require "sidekiq/fetch"

module Sidekiq
  module Pauzer
    # Default Sidekiq's BasicFetch infused with Pauzer
    class BasicFetch < Sidekiq::BasicFetch
      private

      def queues_cmd
        super - Pauzer.paused_queues.map { |name| "queue:#{name}" }
      end
    end
  end
end
