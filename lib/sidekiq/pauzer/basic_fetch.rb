# frozen_string_literal: true

require "sidekiq"
require "sidekiq/fetch"

module Sidekiq
  module Pauzer
    # Default Sidekiq's BasicFetch infused with Pauzer
    class BasicFetch < Sidekiq::BasicFetch
      private

      def queues_cmd
        queues =
          if @strictly_ordered_queues
            @queues
          else
            permute = @queues.dup
            permute.shuffle!
            permute.uniq!
            permute
          end

        queues - Pauzer.paused_queues.map { |name| "queue:#{name}" }
      end
    end
  end
end
