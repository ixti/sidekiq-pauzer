# frozen_string_literal: true

require_relative "lib/sidekiq/pauzer/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-pauzer"
  spec.version       = Sidekiq::Pauzer::VERSION
  spec.authors       = ["Alexey Zapparov"]
  spec.email         = ["alexey@zapparov.com"]

  spec.summary       = "Enhance Sidekiq with queue pausing"
  spec.homepage      = "https://github.com/ixti/sidekiq-pauzer"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/v#{spec.version}/CHANGES.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    docs = %w[LICENSE.txt README.adoc].freeze

    `git ls-files -z`.split("\x0").select do |f|
      f.start_with?("lib/", "web/") || docs.include?(f)
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_runtime_dependency "concurrent-ruby", ">= 1.2.0"
  spec.add_runtime_dependency "sidekiq", ">= 7.2"
end
