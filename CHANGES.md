# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [5.1.0] - 2023-12-11

### Changed

- Poll redis directly when listing paused queues in web UI.


## [5.0.0] - 2023-12-09

### Changed

- Default `Sidekiq::Pauzer::Config#refresh_rate` is now 5 seconds (was 10)
- (BREAKING) `Sidekiq::Pauzer::Config#key_prefix` now accepts only Floats

### Removed

- (BREAKING) Remove `Sidekiq::Pauzer::Config#key_prefix`
- (BREAKING) Drop Sidekiq 7.0 support
- (BREAKING) Drop Sidekiq 7.1 support


## [4.2.1] - 2023-11-26

### Changed

- Migrate development to Github.


## [4.2.0] - 2023-11-23

### Fixed

- Fix UI issues for good this time by ensuring paused queues refresher is
  running everywhere.


## [4.1.0] - 2023-11-22

### Fixed

- Use SMEMBERS instead of SSCAN, as amount of elements will never be huge.
- Improve internal cache handling, should help with random web UI issues.


## [4.0.0] - 2023-11-17

### Changed

- (BREAKING) Replace Sidekiq::Pauzer::BasicFetch with mixin that is prepended to
  Sidekiq::BasicFetch, thus no need to configure fetcher class directly anymore.


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


[unreleased]: https://github.com/ixti/sidekiq-pauzer/compare/v5.1.0...main
[5.1.0]: https://github.com/ixti/sidekiq-pauzer/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/ixti/sidekiq-pauzer/compare/v4.2.1...v5.0.0
[4.2.1]: https://github.com/ixti/sidekiq-pauzer/compare/v4.2.0...v4.2.1
[4.2.0]: https://github.com/ixti/sidekiq-pauzer/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/ixti/sidekiq-pauzer/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/ixti/sidekiq-pauzer/compare/v3.1.0...v4.0.0
[3.1.0]: https://github.com/ixti/sidekiq-pauzer/compare/v3.0.1...v3.1.0
[3.0.1]: https://github.com/ixti/sidekiq-pauzer/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/ixti/sidekiq-pauzer/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/ixti/sidekiq-pauzer/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/ixti/sidekiq-pauzer/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/ixti/sidekiq-pauzer/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/ixti/sidekiq-pauzer/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ixti/sidekiq-pauzer/tree/v1.0.0
