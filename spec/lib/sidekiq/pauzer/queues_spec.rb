# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer::Queues do
  subject(:queues) { described_class.new(refresh_rate, repository: repository) }

  let(:refresh_rate) { 0.1 }
  let(:repository)   { Sidekiq::Pauzer::Repository.new }

  after { queues.stop_refresher }

  it { is_expected.to be_an Enumerable }

  it "polls repository regularily" do
    allow(repository).to receive(:to_a).and_call_original

    queues.start_refresher
    sleep(4 * refresh_rate)

    expect(repository).to have_received(:to_a).at_least(4).times
    expect(repository).to have_received(:to_a).at_most(5).times
  end

  context "when repository poll fails" do
    before do
      attempt = 0

      allow(repository).to receive(:to_a).and_wrap_original do |m|
        attempt += 1

        if attempt <= 4
          raise "nope" if attempt.odd?

          repository.add("q#{attempt}")
        end

        m.call
      end

      queues.start_refresher
      sleep(4 * refresh_rate)
    end

    it "keeps refresher runnning" do
      expect(queues.refresher_running?).to be true
    end

    it "keeps updating the local cache" do
      expect(queues.to_a).to contain_exactly("q2", "q4")
    end
  end

  describe "#each" do
    subject { queues.each { |q| yielded_results << q } }

    let(:yielded_results) { [] }

    before do
      repository.add("foo")
      repository.add("bar")
    end

    it { is_expected.to be queues }

    it "yields each paused queue" do
      queues.start_refresher
      sleep refresh_rate

      expect { subject }.to change { yielded_results }.to(match_array(%w[foo bar]))
    end

    context "without block given" do
      subject { queues.each }

      it { is_expected.to be_an Enumerator }

      it "returns each paused queue" do
        queues.start_refresher
        sleep refresh_rate

        expect(subject).to contain_exactly("foo", "bar")
      end
    end
  end

  describe "#start_refresher" do
    it "starts asynchronous refresher" do
      expect { queues.start_refresher }.to change(queues, :refresher_running?).to(true)
    end
  end

  describe "#stop_refresher" do
    before { queues.start_refresher }

    it "stops asynchronous refresher" do
      expect { queues.stop_refresher }.to change(queues, :refresher_running?).to(false)
    end
  end

  describe "#refresher_running?" do
    subject { queues.refresher_running? }

    it { is_expected.to be false }

    context "when refresher was stopped" do
      before { queues.stop_refresher }

      it { is_expected.to be false }
    end

    context "when refresher was started" do
      before { queues.start_refresher }

      it { is_expected.to be true }
    end
  end
end
