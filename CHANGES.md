# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [3.1.0] - 2023-05-18

### Changed

- Remove synchronization around internal queues list dup/replace, as those are
  thread-safe. This makes calling `Sidekiq::Pauzer.paused_queues` faster.


## [3.0.1] - 2023-05-14

### Changed

- Simplify BasicFetch implementation.
- Fix changelog.


## [3.0.0] - 2023-05-14

### Removed

- Drop support of Sidekiq 6.5.x.
- Remove `Sidekiq::Pauzer.paused_queue_names`.


## [2.2.0] - 2023-05-18

### Changed

- Backport synchronization removal around internal queues list dup/replace
  from [v3.1.0](https://gitlab.com/ixti/sidekiq-pauzer/-/tree/v3.1.0)


## [2.1.0] - 2023-05-12

### Changed

- `Sidekiq::Pauzer.paused_queues` now returns list of paused queue names (was
  list of paused queues redis keys).

### Deprecated

- Restore and deprecate `Sidekiq::Pauzer.paused_queue_names`.
  Will be removed in [3.0.0].


## [2.0.0] - 2023-05-12 [YANKED]

### Changed

- `Sidekiq::Pauzer.paused_queues` now returns names without `queue:` prefix.

### Removed

- Remove `Sidekiq::Pauzer.paused_queue_names`.


## [1.1.0] - 2023-05-12

### Deprecated

- Deprecate `Sidekiq::Pauzer.paused_queues`. Will change behaviour in [2.0.0].


## [1.0.0] - 2023-05-09

### Added

- Initial release that supports sidekiq >= 6.5.0


[unreleased]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v3.1.0...main
[3.1.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v3.0.1...v3.1.0
[3.0.1]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v3.0.0...v3.0.1
[3.0.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v2.1.0...v3.0.0
[2.1.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v2.0.0...v2.1.0
[2.0.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v1.1.0...v2.0.0
[1.1.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/compare/v1.0.0...v1.1.0
[1.0.0]: https://gitlab.com/ixti/sidekiq-pauzer/-/tree/v1.0.0
