# frozen_string_literal: true

require "rack/test"
require "capybara/rspec"

require "sidekiq/pauzer/web"

RSpec.describe Sidekiq::Pauzer::Web do
  include Rack::Test::Methods

  def app
    @app ||= Sidekiq::Web.new
  end

  let(:redis_key) { Sidekiq::Pauzer.redis_key }

  before do
    Sidekiq::Pauzer.instance_variable_get(:@queues).__send__(:refresh)

    Capybara.app = app
  end

  it "enhances application with queue pause/resume handler" do
    post "/queues/foo", "pause" => "1"
    expect(last_response.status).to eq 302
    expect(redis_smembers(redis_key)).to contain_exactly("foo")

    post "/queues/bar", "pause" => "1"
    expect(last_response.status).to eq 302
    expect(redis_smembers(redis_key)).to contain_exactly("foo", "bar")

    post "/queues/foo", "unpause" => "1"
    expect(last_response.status).to eq 302
    expect(redis_smembers(redis_key)).to contain_exactly("bar")
  end

  it "enhances queues list view with pause/resume buttons", type: :feature do # rubocop:disable RSpec/ExampleLength
    Sidekiq::Client.push("queue" => :foo, "class" => PauzerTestJob, "args" => [])
    Sidekiq::Client.push("queue" => :bar, "class" => PauzerTestJob, "args" => [])

    visit "/queues"

    expect(find("form[action='/queues/foo']")).to have_button("Pause").and have_no_button("Unpause")
    expect(find("form[action='/queues/bar']")).to have_button("Pause").and have_no_button("Unpause")

    find("form[action='/queues/foo']").click_button("Pause")

    visit "/queues"

    expect(find("form[action='/queues/foo']")).to have_no_button("Pause").and have_button("Unpause")
    expect(find("form[action='/queues/bar']")).to have_button("Pause").and have_no_button("Unpause")

    find("form") { |f| f["action"] == "/queues/foo" }.click_button("Unpause")

    visit "/queues"

    expect(find("form[action='/queues/foo']")).to have_button("Pause").and have_no_button("Unpause")
    expect(find("form[action='/queues/bar']")).to have_button("Pause").and have_no_button("Unpause")
  end

  describe ".unpatch_views!" do
    before { described_class.unpatch_views! }

    after { Sidekiq::Pauzer::Patches::WebAction.apply! }

    it "restores original view template", type: :feature do
      Sidekiq::Client.push("queue" => :foo, "class" => PauzerTestJob, "args" => [])
      Sidekiq::Client.push("queue" => :bar, "class" => PauzerTestJob, "args" => [])

      visit "/queues"

      expect(find("form[action='/queues/foo']")).to have_no_button("Pause").and have_no_button("Unpause")
      expect(find("form[action='/queues/bar']")).to have_no_button("Pause").and have_no_button("Unpause")
    end
  end
end
