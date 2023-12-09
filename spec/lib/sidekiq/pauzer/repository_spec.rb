# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer::Repository do
  subject(:repository) { described_class.new }

  it { is_expected.to be_an Enumerable }

  describe "#each" do
    subject { repository.each { |inhibitor| yielded_results << inhibitor } }

    let(:yielded_results) { [] }

    before do
      redis_sadd("a")
      redis_sadd("b")
      redis_sadd("c")
    end

    it { is_expected.to be repository }

    it "yields each paused queue" do
      expect { subject }.to(change { yielded_results }.to(contain_exactly("a", "b", "c")))
    end

    context "without block given" do
      subject { repository.each }

      it { is_expected.to be_an Enumerator }

      it "returns each valid inhibitor" do
        expect(subject).to contain_exactly("a", "b", "c")
      end
    end
  end

  describe "#add" do
    before do
      redis_sadd("a")
      redis_sadd("b")
    end

    it "adds paused queue to redis" do
      expect { repository.add("c") }.to(
        change { redis_smembers }.to(contain_exactly("a", "b", "c"))
      )
    end

    context "when given queue is already in the paused list" do
      it "does nothing" do
        expect { repository.add("b") }.to(keep_unchanged { redis_smembers })
      end
    end
  end

  describe "#delete" do
    subject { repository.delete("b") }

    before do
      redis_sadd("a")
      redis_sadd("b")
    end

    it "removes paused queue" do
      expect { subject }.to(change { redis_smembers }.to(contain_exactly("a")))
    end

    context "when queue is not paused" do
      subject { repository.delete("deadbeef") }

      it "does nothing" do
        expect { subject }.to(keep_unchanged { redis_smembers })
      end
    end
  end

  describe "#include?" do
    subject { repository.include?("a") }

    it { is_expected.to be false }

    context "when given queue name is in the paused queues list" do
      before { redis_sadd("a") }

      it { is_expected.to be true }
    end
  end
end
