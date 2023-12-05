# frozen_string_literal: true

require "bundler/setup"

require "sidekiq"
require "sidekiq/pauzer"

class PauzerDemoJob
  include Sidekiq::Job

  def perform(num)
    puts "performing #{num}..."
    sleep 1
  end
end
