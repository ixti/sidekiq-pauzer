# frozen_string_literal: true

require "sidekiq"
require "sidekiq/api"

module Sidekiq
  module Pauzer
    module Patches
      module Queue
        def self.apply!
          Sidekiq::Queue.prepend(self)
        end

        def paused?
          Pauzer.paused?(name)
        end

        def pause!
          Pauzer.pause!(name)
        end

        def unpause!
          Pauzer.unpause!(name)
        end
      end
    end
  end
end
