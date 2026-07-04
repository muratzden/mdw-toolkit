# Changelog

All notable changes to this project will be documented in this file.

The format of this changelog is based on Keep a Changelog and this project follows Semantic Versioning.

---

## [1.1.0] - 2026-07-03

### Added

* Compliance Suite foundation.
* Compliance command and shared compliance result object.
* Compliance prefix validator for WordPress-safe identifiers.
* Dry-run and backed-up compliance prefix fixer.
* Re-enabled prefix fixer apply mode with semantic-safe line-aware replacements.`r`n* Restricted prefix fixer planning to semantic PHP and known WordPress identifiers.`r`n* `mdw lint` command for PHP syntax checks.
* `mdw validate` release readiness flow.
* Command-specific help pages with `mdw help <command>`.
* WP-CLI mode for `mdw plugin-check` with WordPress test path support.
* GitHub Actions workflow for automated test execution.

### Changed

* Standardized validate output through the shared CLI output layer.
* Updated release pipeline to run backup, build, validate and ZIP stages.
* Improved build exclusion rules for production packages.
* Updated toolkit metadata to v1.1.0 Stable.
* Refreshed README for public v1.1 release readiness.

### Fixed

* Removed output helper name collisions that could override core CLI helpers.
* Replaced hardcoded validate plugin path resolution with the central path service.
* Improved plugin-check handling for empty WP-CLI output lines.

---

## [1.0.0] - 2026-07-02

### Added

* Initial public release.
* CLI Foundation.
* Command Router.
* Command Registry.
* Services Layer.
* Validators.
* Workspace Intelligence.
* Build Pipeline.
* ZIP Pipeline.
* Release Pipeline.
* Git Foundation.
* LocalWP Foundation.
* Centralized configuration (`mdw.json`).
* Shared CLI user interface.
* Automated backup workflow.
* Production-ready workspace architecture.
* Automated test suite.

### Changed

* Standardized command behavior across the entire CLI.
* Unified workspace management.
* Improved command output consistency.
* Optimized service architecture.
* Refined build and release workflows.
* Completed productization phase.
* Improved project documentation.
* Prepared repository for public release.

### Removed

* Legacy helper functions.
* Legacy runtime components.
* Unused helper scripts.
* Obsolete internal references.

### Fixed

* Command consistency improvements.
* Runtime stability improvements.
* Service initialization refinements.
* Build pipeline reliability.
* Release pipeline reliability.
* General production hardening.





