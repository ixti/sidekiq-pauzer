# frozen_string_literal: true

require "sidekiq"
require "sidekiq/fetch"

module Sidekiq
  module Pauzer
    # Default Sidekiq's BasicFetch infused with Pauzer
    class BasicFetch < Sidekiq::BasicFetch
      private

      if Gem::Version.new("7.0.0") <= Gem::Version.new(Sidekiq::VERSION)
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
          if @strictly_ordered_queues
            *queues, timeout = @queues

            (queues - Pauzer.paused_queues) << timeout
          else
            permute = (@queues - Pauzer.paused_queues)
            permute.shuffle!
            permute.uniq!
            permute << { timeout: Sidekiq::BasicFetch::TIMEOUT }
          end
        end
      end
    end
  end
end
