# frozen_string_literal: true

require "bundler/setup"

require "sidekiq"
require "sidekiq/pauzer"

class PauzerDemoJob
  include Sidekiq::Job

  def perform
    sleep 1
  end
end
