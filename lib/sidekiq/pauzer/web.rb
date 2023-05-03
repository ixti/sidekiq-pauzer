# frozen_string_literal: true

require "erb"
require "sidekiq"
require "sidekiq/web"

require_relative "../pauzer"

module Sidekiq
  module Pauzer
    def self.unpatch_views!
      WebAction.remove_method(:_erb_queues)
    end
  end

  class WebApplication
    @routes[Sidekiq::WebRouter::POST].delete_if do |web_route|
      web_route.pattern == "/queues/:name"
    end

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

    class_eval <<-RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
      def _erb_queues
        #{PAUZER_QUEUES_TEMPLATE}
      end
    RUBY
  end
end
