# frozen_string_literal: true

require_relative "./patches/web_action"
require_relative "./patches/web_application"

module Sidekiq
  module Pauzer
    module Web
      def self.unpatch_views!
        Patches::WebAction.revert!
      end
    end
  end
end

Sidekiq::Pauzer::Patches::WebAction.apply!
Sidekiq::Pauzer::Patches::WebApplication.apply!
