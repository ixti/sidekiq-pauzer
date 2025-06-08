# frozen_string_literal: true

require "sidekiq"
require "sidekiq/web"

module Sidekiq
  module Pauzer
    module Patches
      # @private
      module WebApplication
        class << self
          def apply!
            remove_theirs_queue_update_route
            register_ours_queue_update_route
          end

          private

          def remove_theirs_queue_update_route
            Sidekiq::Web::Application
              .route_cache
              .fetch(:post)
              .delete_if { |route| route.pattern == "/queues/:name" }
          end

          def register_ours_queue_update_route # rubocop:disable Metrics/MethodLength
            Sidekiq::Web::Application.class_exec do
              post "/queues/:name" do
                queue = Sidekiq::Queue.new(route_params(:name))

                if request.params["pause"]
                  queue.pause!
                elsif request.params["unpause"]
                  queue.unpause!
                else
                  queue.clear
                end

                redirect "#{root_path}queues"
              end
            end
          end
        end
      end
    end
  end
end
