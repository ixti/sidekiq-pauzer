# frozen_string_literal: true

require "sidekiq"
require "sidekiq/api"

module Sidekiq
  module Pauzer
    module Patches
      # @private
      module Queue
        def paused?
          Pauzer.paused?(name)
        end

        def pause!
          Pauzer.pause!(name)
          nil
        end

        def unpause!
          Pauzer.unpause!(name)
          nil
        end
      end
    end
  end
end

Sidekiq::Queue.prepend(Sidekiq::Pauzer::Patches::Queue)
