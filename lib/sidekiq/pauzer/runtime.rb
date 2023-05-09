# frozen_string_literal: true

require "sidekiq"

module Sidekiq
  module Pauzer
    module Runtime
      SIDEKIQ_SEVEN = Gem::Version.new("7.0.0") <= Gem::Version.new(Sidekiq::VERSION)
    end
  end
end
