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
          queues =
            if @strictly_ordered_queues
              @queues
            else
              permute = @queues.dup
              permute.shuffle!
              permute.uniq!
              permute
            end

          excluding_paused(queues)
        end
      else
        def queues_cmd
          queues =
            if @strictly_ordered_queues
              @queues[0...-1]
            else
              permute = @queues.dup
              permute.shuffle!
              permute.uniq!
              permute
            end

          excluding_paused(queues) << { timeout: Sidekiq::BasicFetch::TIMEOUT }
        end
      end

      def excluding_paused(queues)
        queues - Pauzer.paused_queue_names.map { |name| "queue:#{name}" }
      end
    end
  end
end
