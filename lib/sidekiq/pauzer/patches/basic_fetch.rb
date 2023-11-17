# frozen_string_literal: true

require "sidekiq"
require "sidekiq/fetch"

module Sidekiq
  module Pauzer
    module Patches
      # Default Sidekiq's BasicFetch infused with Pauzer
      module BasicFetch
        private

        def queues_cmd
          super - Pauzer.paused_queues.map { |name| "queue:#{name}" }
        end
      end
    end
  end
end

Sidekiq::BasicFetch.prepend(Sidekiq::Pauzer::Patches::BasicFetch)
