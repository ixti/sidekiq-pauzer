# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer::Queues do
  subject(:queues) { described_class.new(config) }

  let(:config) { Sidekiq::Pauzer::Config.new }

  it { is_expected.to be_an Enumerable }

  describe "#each" do
    before do
      queues.pause! "foo"
      queues.pause! "bar"
    end

    context "with block given" do
      subject { queues.each { |q| yielded_results << q } }

      let(:yielded_results) { [] }

      it "yields each paused queue" do
        expect { subject }.to change { yielded_results }.to(match_array(%w[foo bar]))
      end

      it { is_expected.to be queues }
    end

    context "without block given" do
      subject { queues.each }

      it { is_expected.to be_an Enumerator }

      it { is_expected.to match_array %w[foo bar] }
    end
  end

  describe "#pause!" do
    it "adds queue to the paused list" do
      expect { %w[foo bar].each { |q| queues.pause!(q) } }
        .to change { redis_smembers(config.redis_key) }.to(match_array(%w[foo bar]))
        .and change(queues, :to_a).to(match_array(%w[foo bar]))
    end

    it "support queue name given as Symbol" do
      expect { %i[foo bar].each { |q| queues.pause!(q) } }
        .to change { redis_smembers(config.redis_key) }.to(match_array(%w[foo bar]))
        .and change(queues, :to_a).to(match_array(%w[foo bar]))
    end

    it "avoids duplicates" do
      queues.pause! "foo"

      expect { %w[foo bar].each { |q| queues.pause!(q) } }
        .to change { redis_smembers(config.redis_key) }.to(match_array(%w[foo bar]))
        .and change(queues, :to_a).to(match_array(%w[foo bar]))
    end
  end

  describe "#unpause!" do
    before do
      queues.pause! "foo"
      queues.pause! "bar"
    end

    it "removes queue from the paused list" do
      expect { queues.unpause!("foo") }
        .to change { redis_smembers(config.redis_key) }.to(contain_exactly("bar"))
        .and change(queues, :to_a).to(contain_exactly("bar"))
    end

    it "support queue name given as Symbol" do
      expect { queues.unpause!(:foo) }
        .to change { redis_smembers(config.redis_key) }.to(contain_exactly("bar"))
        .and change(queues, :to_a).to(contain_exactly("bar"))
    end

    it "skips non-paused queues" do
      expect { queues.unpause!("baz") }
        .to keep_unchanged { redis_smembers(config.redis_key) }
        .and keep_unchanged(queues, :to_a)
    end
  end

  describe "#paused?" do
    context "when queue is not paused" do
      it "returns ‹false›" do
        expect(queues.paused?("foo")).to be false
      end

      it "support queue name given as Symbol" do
        expect(queues.paused?(:foo)).to be false
      end
    end

    context "when queue is paused" do
      before { queues.pause!("foo") }

      it "returns ‹true›" do
        expect(queues.paused?("foo")).to be true
      end

      it "support queue name given as Symbol" do
        expect(queues.paused?(:foo)).to be true
      end
    end
  end

  describe "#start_refresher" do
    before { config.refresh_rate = 0.1 }

    after { queues.stop_refresher }

    it "starts asynchronous refresher" do
      queues.start_refresher

      expect { with_sleep(0.2) { redis_sadd(config.redis_key, "foo") } }
        .to change(queues, :to_a).to(contain_exactly("foo"))
    end
  end

  describe "#stop_refresher" do
    before do
      config.refresh_rate = 0.1
      queues.start_refresher
    end

    after { queues.stop_refresher }

    it "stops asynchronous refresher" do
      queues.stop_refresher

      expect { with_sleep(0.2) { redis_sadd(config.redis_key, "foo") } }
        .to keep_unchanged(queues, :to_a)
    end
  end

  describe "#refresher_running?" do
    subject { queues.refresher_running? }

    after { queues.stop_refresher }

    it { is_expected.to be false }

    context "when refresher was stopped" do
      before do
        queues.start_refresher
        queues.stop_refresher
      end

      it { is_expected.to be false }
    end

    context "when refresher was started" do
      before { queues.start_refresher }

      it { is_expected.to be true }
    end
  end
end
