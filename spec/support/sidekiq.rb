# frozen_string_literal: true

require "sidekiq"
require "sidekiq/cli"

require_relative "./redis"

$TESTING = true # rubocop:disable Style/GlobalVars

if Gem::Version.new("7.0.0") <= Gem::Version.new(Sidekiq::VERSION)
  raise "sidekiq >= 7.0 only supports redis-client gem" if "redis-client" != REDIS_GEM
else
  case REDIS_GEM
  when "redis-client"
    ENV["SIDEKIQ_REDIS_CLIENT"] = "1"
  when "redis-namespace"
    with_redis_namespace = proc do |config|
      config.redis = { namespace: REDIS.namespace }
    end
    Sidekiq.configure_server(&with_redis_namespace)
    Sidekiq.configure_client(&with_redis_namespace)
  end
end
