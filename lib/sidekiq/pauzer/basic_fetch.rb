# frozen_string_literal: true

require "sidekiq"
require "sidekiq/fetch"

require_relative "./runtime"

module Sidekiq
  module Pauzer
    # Default Sidekiq's BasicFetch infused with Pauzer
    class BasicFetch < Sidekiq::BasicFetch
      private

      if Runtime::SIDEKIQ_SEVEN
        def queues_cmd
          if @strictly_ordered_queues
            @queues - Pauzer.paused_queues
          else
            permute = (@queues - Pauzer.paused_queues)
            permute.shuffle!
            permute.uniq!
            permute
          end
        end
      else
        def queues_cmd
          queues =
            if @strictly_ordered_queues
              @queues[0...-1] - Pauzer.paused_queues
            else
              permute = (@queues - Pauzer.paused_queues)
              permute.shuffle!
              permute.uniq!
              permute
            end

          queues << { timeout: Sidekiq::BasicFetch::TIMEOUT }
        end
      end
    end
  end
end
