# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer do
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
        .to change { redis_smembers }.to(match_array(%w[foo bar]))
    end

    it "avoids duplicates" do
      expect { %w[foo bar foo].each { |q| described_class.pause!(q) } }
        .to change { redis_smembers }.to(match_array(%w[foo bar]))
    end
  end

  describe ".unpause!" do
    before do
      described_class.pause!("foo")
      described_class.pause!("bar")
    end

    it "removes queue from the paused list" do
      expect { described_class.unpause!("foo") }
        .to change { redis_smembers }.to(contain_exactly("bar"))
    end

    it "skips non-paused queues" do
      expect { described_class.unpause!("baz") }
        .to(keep_unchanged { redis_smembers })
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
    before do
      described_class.configure { |c| c.refresh_rate = 0.1 }
    end

    it "returns eventually consistent list of paused queue names" do
      described_class.pause! "foo"
      described_class.pause! "bar"

      expect(described_class.paused_queues).to be_empty

      described_class.startup
      sleep 0.1

      expect(described_class.paused_queues).to contain_exactly("foo", "bar")
    end
  end

  describe ".configure" do
    it "yields config object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class::Config)
    end

    it "allows re-entrance" do
      described_class.configure { |c| c.refresh_rate = 42.0 }

      expect { |b| described_class.configure(&b) }
        .to yield_with_args(have_attributes(refresh_rate: 42.0))
    end
  end

  describe ".startup" do
    after { described_class.shutdown }

    it "starts asynchronous refresher" do
      expect { described_class.startup }
        .to change { described_class.instance_variable_get(:@queues).refresher_running? }.to(true)
    end
  end

  describe ".shutdown" do
    before { described_class.startup }

    it "stops asynchronous refresher" do
      expect { described_class.shutdown }
        .to change { described_class.instance_variable_get(:@queues).refresher_running? }.to(false)
    end
  end
end
