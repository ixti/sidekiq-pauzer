# frozen_string_literal: true

RSpec.describe Sidekiq::Pauzer::Config do
  subject(:config) { described_class.new }

  describe "#redis_key" do
    subject { config.redis_key }

    context "when key prefix was not set" do
      it { is_expected.to eq "sidekiq-pauzer" }
    end

    context "when key prefix was provided" do
      before { config.key_prefix = "my-app:" }

      it { is_expected.to eq "my-app:sidekiq-pauzer" }
    end
  end

  describe "#refresh_rate" do
    subject { config.refresh_rate }

    context "with default value" do
      it { is_expected.to eq 10 }
    end

    context "when refresh rate was overridden" do
      before { config.refresh_rate = 42 }

      it { is_expected.to eq 42 }
    end
  end

  describe "#key_prefix=" do
    it "sets prefix of the redis key" do
      expect { config.key_prefix = "my-app:" }
        .to change(config, :redis_key).to "my-app:sidekiq-pauzer"
    end

    it "allows clear out previously set key prefix" do
      config.key_prefix = "my-app:"

      expect { config.key_prefix = nil }
        .to change(config, :redis_key).to "sidekiq-pauzer"
    end

    it "fails if given value is neither ‹nil›, nor ‹String›" do
      expect { config.key_prefix = :nope }
        .to raise_error(ArgumentError, %r{expected String, or nil})
    end
  end

  describe "#refresh_rate=" do
    where(value: [42, 42.5])
    with_them do
      it "allows override refresh rate" do
        expect { config.refresh_rate = value }
          .to change(config, :refresh_rate).to value
      end
    end

    it "fails if given value is neither ‹Float›, nor ‹Integer›" do
      expect { config.refresh_rate = "42" }
        .to raise_error(ArgumentError, %r{expected Integer, or Float})
    end
  end
end
