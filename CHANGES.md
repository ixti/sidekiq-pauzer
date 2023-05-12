# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [2.1.0] - 2023-05-12

### Changed

- `Sidekiq::Pauzer.paused_queues` now returns list of paused queue names (was
  list of paused queues redis keys).


## [1.1.0] - 2023-05-12

### Deprecated

- `Sidekiq::Pauzer.paused_queues` marked as deprecated.


## [1.0.0] - 2023-05-09

### Added

- Initial release that supports sidekiq >= 6.5.0


[unreleased]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v2.1.0...main
[2.1.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v1.1.0...v2.1.0
[1.1.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v1.0.0...v1.1.0
[1.0.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/tree/v1.0.0
