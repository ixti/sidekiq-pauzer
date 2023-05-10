# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer do
  def sidekiq_fire_event(...)
    if Sidekiq::Pauzer::Runtime::SIDEKIQ_SEVEN
      Sidekiq.default_configuration.default_capsule.fire_event(...)
    else
      runner = Object.new
      runner.instance_variable_set(:@config, Sidekiq)
      runner.extend(Sidekiq::Component)
      runner.fire_event(...)
    end
  end

  before { described_class.instance_variable_get(:@queues).__send__(:refresh) }

  it "registers startup handler" do
    allow(described_class).to receive(:startup)

    sidekiq_fire_event(:startup)

    expect(described_class).to have_received(:startup)
  end

  it "registers shutdown handler" do
    allow(described_class).to receive(:shutdown)

    sidekiq_fire_event(:shutdown)

    expect(described_class).to have_received(:shutdown)
  end

  describe ".pause!" do
    it "adds queue to the paused list" do
      expect { %w[foo bar].each { |q| described_class.pause!(q) } }
        .to change { redis_smembers(described_class.redis_key) }.to(match_array(%w[foo bar]))
        .and change(described_class, :paused_queues).to(match_array(%w[queue:foo queue:bar]))
    end

    it "support queue name given as Symbol" do
      expect { %i[foo bar].each { |q| described_class.pause!(q) } }
        .to change { redis_smembers(described_class.redis_key) }.to(match_array(%w[foo bar]))
        .and change(described_class, :paused_queues).to(match_array(%w[queue:foo queue:bar]))
    end

    it "avoids duplicates" do
      described_class.pause!("foo")

      expect { %w[foo bar].each { |q| described_class.pause!(q) } }
        .to change { redis_smembers(described_class.redis_key) }.to(match_array(%w[foo bar]))
        .and change(described_class, :paused_queues).to(match_array(%w[queue:foo queue:bar]))
    end
  end

  describe ".unpause!" do
    before do
      described_class.pause!("foo")
      described_class.pause!("bar")
    end

    it "removes queue from the paused list" do
      expect { described_class.unpause!("foo") }
        .to change { redis_smembers(described_class.redis_key) }.to(contain_exactly("bar"))
        .and change(described_class, :paused_queues).to(contain_exactly("queue:bar"))
    end

    it "support queue name given as Symbol" do
      expect { described_class.unpause!(:foo) }
        .to change { redis_smembers(described_class.redis_key) }.to(contain_exactly("bar"))
        .and change(described_class, :paused_queues).to(contain_exactly("queue:bar"))
    end

    it "skips non-paused queues" do
      expect { described_class.unpause!("baz") }
        .to keep_unchanged { redis_smembers(described_class.redis_key) }
        .and keep_unchanged(described_class, :paused_queues)
    end
  end

  describe ".paused?" do
    context "when queue is not paused" do
      it "returns ‹false›" do
        expect(described_class.paused?("foo")).to be false
      end

      it "support queue name given as Symbol" do
        expect(described_class.paused?(:foo)).to be false
      end
    end

    context "when queue is paused" do
      before { described_class.pause!("foo") }

      it "returns ‹true›" do
        expect(described_class.paused?("foo")).to be true
      end

      it "support queue name given as Symbol" do
        expect(described_class.paused?(:foo)).to be true
      end
    end
  end

  describe ".paused_queues" do
    it "returns list of paused queue names with `queue:` prefix" do
      expect { %w[foo bar].each { |q| described_class.pause!(q) } }
        .to change(described_class, :paused_queues).to(match_array(%w[queue:foo queue:bar]))
    end
  end

  describe ".configure" do
    it "yields config object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class::Config)
    end

    it "allows re-entrance" do
      described_class.configure do |c|
        c.key_prefix   = "foobar:"
        c.refresh_rate = 42
      end

      expect { |b| described_class.configure(&b) }
        .to yield_with_args(have_attributes(key_prefix: "foobar:", refresh_rate: 42))
    end

    it "restarts queues refresher if it was already started" do
      redis_sadd(described_class.redis_key, "foo")

      described_class.configure do |c|
        c.key_prefix   = "v2:"
        c.refresh_rate = 0.1
      end

      described_class.startup
      described_class.configure { |c| c.key_prefix = nil }

      sleep 0.2

      expect(described_class.paused_queues).to contain_exactly("queue:foo")
    end
  end

  describe ".startup" do
    before do
      described_class.configure do |config|
        config.refresh_rate = 0.1
      end
    end

    after { described_class.shutdown }

    it "starts asynchronous refresher" do
      described_class.startup

      expect { with_sleep(0.2) { redis_sadd(described_class.redis_key, "foo") } }
        .to change(described_class, :paused_queues).to(contain_exactly("queue:foo"))
    end
  end

  describe ".shutdown" do
    before do
      described_class.configure do |config|
        config.refresh_rate = 0.1
      end

      described_class.startup
    end

    after { described_class.shutdown }

    it "stops asynchronous refresher" do
      described_class.shutdown

      expect { with_sleep(0.2) { redis_sadd(described_class.redis_key, "foo") } }
        .to keep_unchanged(described_class, :paused_queues)
    end
  end
end
