# frozen_string_literal: true

require "sidekiq"
require "sidekiq/cli"

$TESTING = true # rubocop:disable Style/GlobalVars

class PauzerTestJob
  include Sidekiq::Job

  def perform; end
end

module PauzerTestingContext
  def sidekiq_fire_event(...)
    Sidekiq.default_configuration.default_capsule.fire_event(...)
  end

  def redis_smembers(key)
    Sidekiq.redis { |conn| conn.call("SMEMBERS", key) }
  end

  def redis_sadd(key, value)
    Sidekiq.redis { |conn| conn.call("SADD", key, value) }
  end
end

RSpec.configure do |config|
  config.include(PauzerTestingContext)

  config.before do
    Sidekiq.redis { |conn| conn.call("FLUSHDB") }
  end
end
