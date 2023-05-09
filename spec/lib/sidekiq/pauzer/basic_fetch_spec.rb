# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer::BasicFetch do
  subject(:fetch) do
    if Sidekiq::Pauzer::Runtime::SIDEKIQ_SEVEN
      config = Sidekiq::Config.new
      config.queues = queues
      described_class.new(config.default_capsule)
    else
      Sidekiq.instance_variable_set(:@config, Sidekiq::DEFAULTS.dup)
      Sidekiq.queues = queues
      described_class.new(Sidekiq)
    end
  end

  let(:queues) { ["foo,1", "bar,2", "baz,3"] }

  before do
    Sidekiq::Pauzer.pause!(:foo)
    stub_const("Sidekiq::BasicFetch::TIMEOUT", 0.1)
  end

  describe "#retrieve_work" do
    before do
      Sidekiq::Client.push("queue" => :foo, "class" => PauzerTestJob, "args" => [])
      Sidekiq::Client.push("queue" => :bar, "class" => PauzerTestJob, "args" => [])
      Sidekiq::Client.push("queue" => :baz, "class" => PauzerTestJob, "args" => [])
    end

    it "fetches non-paused queues only" do
      expect(Array.new(3) { fetch.retrieve_work }.filter_map { _1&.queue_name })
        .to match_array(%w[bar baz])
    end

    context "with strict order" do
      let(:queues) { %w[foo bar baz] }

      it "fetches non-paused queues only in strict order" do
        expect(Array.new(3) { fetch.retrieve_work }.filter_map { _1&.queue_name })
          .to eq(%w[bar baz])
      end
    end
  end

  describe "#queues_cmd" do
    subject(:queues_cmd) { fetch.__send__(:queues_cmd) }

    it "returns non-paused queues only" do
      if Sidekiq::Pauzer::Runtime::SIDEKIQ_SEVEN
        expect(queues_cmd).to match_array(%w[queue:bar queue:baz])
      else
        *queues, options = queues_cmd

        expect(queues).to match_array(%w[queue:bar queue:baz])
        expect(options).to eq({ timeout: Sidekiq::BasicFetch::TIMEOUT })
      end
    end

    context "with strict order" do
      let(:queues) { %w[foo bar baz] }

      it "fetches non-paused queues only in strict order" do
        if Sidekiq::Pauzer::Runtime::SIDEKIQ_SEVEN
          expect(queues_cmd).to eq(%w[queue:bar queue:baz])
        else
          *queues, options = queues_cmd

          expect(queues).to eq(%w[queue:bar queue:baz])
          expect(options).to eq({ timeout: Sidekiq::BasicFetch::TIMEOUT })
        end
      end
    end
  end
end
