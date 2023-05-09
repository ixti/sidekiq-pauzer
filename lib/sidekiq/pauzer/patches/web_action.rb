# frozen_string_literal: true

require "erb"

require "sidekiq"
require "sidekiq/web"

module Sidekiq
  module Pauzer
    module Patches
      module WebAction
        PAUZER_QUEUES_TEMPLATE =
          ERB.new(File.read(File.expand_path("../../../../web/views/queues.erb", __dir__))).src

        class << self
          def apply!
            revert!

            Sidekiq::WebAction.class_eval <<-RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
              def _erb_queues
                #{PAUZER_QUEUES_TEMPLATE}
              end
            RUBY
          end

          def revert!
            Sidekiq::WebAction.remove_method(:_erb_queues) if Sidekiq::WebAction.method_defined?(:_erb_queues)
          end
        end
      end
    end
  end
end
