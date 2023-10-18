# frozen_string_literal: true

require "capybara/rspec"
require "rack"
require "rack/session"
require "rack/test"
require "securerandom"

require "sidekiq/web"
require "sidekiq/pauzer/web"

RSpec.describe Sidekiq::Pauzer::Web do
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.app do
      use Rack::Session::Cookie, secret: SecureRandom.hex(32), same_site: true
      run Sidekiq::Web
    end
  end

  def csrf_token
    SecureRandom.base64(Sidekiq::Web::CsrfProtection::TOKEN_LENGTH).tap do |csrf|
      env("rack.session", { csrf: csrf })
    end
  end

  let(:redis_key) { Sidekiq::Pauzer.redis_key }

  before do
    Sidekiq::Pauzer.instance_variable_get(:@queues).__send__(:refresh)

    Sidekiq::Client.push("queue" => :foo, "class" => PauzerTestJob, "args" => [])
    Sidekiq::Client.push("queue" => :bar, "class" => PauzerTestJob, "args" => [])

    Capybara.app = app
  end

  describe "POST /queues/:name" do
    it "allows pausing queues" do
      post "/queues/foo", "pause" => "1", "authenticity_token" => csrf_token
      expect(last_response.status).to eq 302
      expect(redis_smembers(redis_key)).to contain_exactly("foo")
      expect(Sidekiq::Pauzer.paused_queues).to contain_exactly("foo")

      post "/queues/bar", "pause" => "1", "authenticity_token" => csrf_token
      expect(last_response.status).to eq 302
      expect(redis_smembers(redis_key)).to contain_exactly("foo", "bar")
      expect(Sidekiq::Pauzer.paused_queues).to contain_exactly("foo", "bar")
    end

    it "allows unpausing queues" do
      Sidekiq::Pauzer.pause!("foo")
      Sidekiq::Pauzer.pause!("bar")

      post "/queues/foo", "unpause" => "1", "authenticity_token" => csrf_token
      expect(last_response.status).to eq 302
      expect(redis_smembers(redis_key)).to contain_exactly("bar")
      expect(Sidekiq::Pauzer.paused_queues).to contain_exactly("bar")

      post "/queues/bar", "unpause" => "1", "authenticity_token" => csrf_token
      expect(last_response.status).to eq 302
      expect(redis_smembers(redis_key)).to be_empty
      expect(Sidekiq::Pauzer.paused_queues).to be_empty
    end

    it "allows clearing the queue" do
      post "/queues/foo", "authenticity_token" => csrf_token

      expect(last_response.status).to eq 302
      expect(Sidekiq::Stats.new.queues).to eq({ "bar" => 1 })
    end
  end

  describe "GET /queues", type: :feature do
    it "allows pausing the queue" do
      visit "/queues"

      expect(find("form[action='/queues/foo']")).to have_button("Pause").and have_no_button("Unpause")
      expect(find("form[action='/queues/bar']")).to have_button("Pause").and have_no_button("Unpause")

      find("form[action='/queues/foo']").click_button("Pause")

      visit "/queues"

      expect(find("form[action='/queues/foo']")).to have_no_button("Pause").and have_button("Unpause")
      expect(find("form[action='/queues/bar']")).to have_button("Pause").and have_no_button("Unpause")
    end

    it "allows unpausing the queue" do
      Sidekiq::Pauzer.pause!("foo")
      Sidekiq::Pauzer.pause!("bar")

      visit "/queues"

      expect(find("form[action='/queues/foo']")).to have_no_button("Pause").and have_button("Unpause")
      expect(find("form[action='/queues/bar']")).to have_no_button("Pause").and have_button("Unpause")

      find("form") { |f| f["action"] == "/queues/foo" }.click_button("Unpause")

      visit "/queues"

      expect(find("form[action='/queues/foo']")).to have_button("Pause").and have_no_button("Unpause")
      expect(find("form[action='/queues/bar']")).to have_no_button("Pause").and have_button("Unpause")
    end

    it "allows clearing the queue" do
      visit "/queues"

      find("form[action='/queues/foo']").click_button("Delete")

      visit "/queues"

      expect(page).not_to have_css("form[action='/queues/foo']")
    end
  end

  describe ".unpatch_views!" do
    before { described_class.unpatch_views! }

    after { Sidekiq::Pauzer::Patches::WebAction.apply! }

    it "restores original view template", type: :feature do
      visit "/queues"

      expect(find("form[action='/queues/foo']")).to have_no_button("Pause").and have_no_button("Unpause")
      expect(find("form[action='/queues/bar']")).to have_no_button("Pause").and have_no_button("Unpause")

      expect(find("form[action='/queues/foo']")).to have_button("Delete")
      expect(find("form[action='/queues/bar']")).to have_button("Delete")
    end
  end
end
