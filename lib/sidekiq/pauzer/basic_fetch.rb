# frozen_string_literal: true

module Sidekiq
  module Pauzer
    # Default Sidekiq's BasicFetch infused with Pauzer
    class BasicFetch < Sidekiq::BasicFetch
      private

      def queues_cmd
        paused_queues = Pauzer.paused_queues
        return super if paused_queues.empty?

        *queues, timeout = super

        (queues - paused_queues) << timeout
      end
    end
  end
end
