# frozen_string_literal: true

require "erb"
require "sidekiq"
require "sidekiq/web"
require "sidekiq/web/application"
require "sidekiq/web/action"

require_relative "../pauzer"

module Sidekiq
  module Pauzer
    def self.unpatch_views!
      WebAction.remove_method(:_erb_queues)
    end
  end

  class WebApplication
    @routes[:POST].delete_if { |web_route| web_route.pattern = "/queues/:name" }

    post "/queues/:name" do
      queue = Sidekiq::Queue.new(route_params[:name])

      if params["pause"]
        queue.pause!
      elsif params["unpause"]
        queue.unpause!
      else
        queue.clear
      end

      redirect "#{root_path}queues"
    end
  end

  class WebAction
    PAUZER_QUEUES_TEMPLATE =
      ERB.new(File.read(File.expand_path("../../../web/views/queues.erb", __dir__))).src

    def _erb_queues
      PAUZER_QUEUES_TEMPLATE
    end
  end
end
