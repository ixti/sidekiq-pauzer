# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer::Patches::Queue do
  it "is injected into Sidekiq::Queue" do
    expect(Sidekiq::Queue).to include(described_class)
  end

  describe "#paused?" do
    subject { Sidekiq::Queue.new("foo").paused? }

    it { is_expected.to be false }

    it "proxies to `Sidekiq::Pauzer.paused?`" do
      allow(Sidekiq::Pauzer).to receive(:paused?).and_call_original

      subject

      expect(Sidekiq::Pauzer).to have_received(:paused?).with("foo")
    end

    context "when queue was paused" do
      before { Sidekiq::Pauzer.pause! "foo" }

      it { is_expected.to be true }
    end
  end

  describe "#pause!" do
    subject { Sidekiq::Queue.new("foo").pause! }

    it "proxies to `Sidekiq::Pauzer.pause!`" do
      allow(Sidekiq::Pauzer).to receive(:pause!).and_call_original

      subject

      expect(Sidekiq::Pauzer).to have_received(:pause!).with("foo")
    end

    it "pauses the queue" do
      Sidekiq::Pauzer.unpause!("foo")

      expect { subject }
        .to change { redis_smembers }.to(contain_exactly("foo"))
        .and change { Sidekiq::Pauzer.paused? "foo" }.to(true)
    end
  end

  describe "#unpause!" do
    subject { Sidekiq::Queue.new("foo").unpause! }

    it "proxies to `Sidekiq::Pauzer.unpause!`" do
      allow(Sidekiq::Pauzer).to receive(:unpause!).and_call_original

      subject

      expect(Sidekiq::Pauzer).to have_received(:unpause!).with("foo")
    end

    it "unpauses the queue" do
      Sidekiq::Pauzer.pause!("foo")

      expect { subject }
        .to change { redis_smembers }.to(be_empty)
        .and change { Sidekiq::Pauzer.paused? "foo" }.to(false)
    end
  end
end
