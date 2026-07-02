# Configuration

## Overview

MDW uses a centralized configuration system to provide a consistent runtime environment across all commands and services.

Rather than storing configuration in multiple locations, all shared settings are managed through a single configuration file.

This approach ensures:

* Consistent command behavior
* Centralized path management
* Shared runtime settings
* Easier maintenance
* Predictable workspace operations

---

## Configuration File

The primary configuration file is:

```text
mdw.json
```

This file acts as the single source of truth for the toolkit.

All commands and services retrieve configuration through the shared configuration layer instead of reading the file directly.

---

## Configuration Goals

The configuration system is designed to:

* Centralize application settings
* Standardize workspace paths
* Store runtime metadata
* Eliminate duplicated configuration logic
* Keep commands independent from configuration storage

---

## Configuration Scope

Typical configuration values include:

* MDW version metadata
* Workspace root directory
* Plugins directory
* Build directory
* Releases directory
* Backups directory
* Runtime options

The exact structure of `mdw.json` may evolve over time, but changes are designed to preserve backward compatibility whenever possible.

---

## Design Principles

The configuration layer follows these principles:

* Single source of truth
* Centralized access
* Shared by all commands
* Independent from business logic
* Easy to maintain
* Easy to validate

Commands should never depend on hardcoded paths or duplicate configuration values.

## Configuration Loading

The configuration is loaded during the application bootstrap process before any command is executed.

The loading process performs the following steps:

1. Locate the configuration file.
2. Read and parse the configuration.
3. Validate the configuration structure.
4. Initialize the configuration service.
5. Make configuration values available to all components.

If the configuration cannot be loaded or validated, execution stops before any operation is performed.

---

## Path Resolution

Workspace paths are resolved exclusively through the configuration layer.

This ensures that every command uses the same directory structure and eliminates inconsistencies caused by hardcoded paths.

Typical paths include:

* Workspace
* Plugins
* Build
* Releases
* Backups

Resolved paths are shared across the application through the configuration service.

---

## Workspace Configuration

The workspace is the foundation of every MDW operation.

All commands assume a standardized workspace layout defined by the active configuration.

Workspace configuration determines:

* Project locations
* Build output location
* Release output location
* Backup destination

Keeping these paths centralized allows the toolkit to remain predictable and easier to maintain.

---

## Validation

Configuration is validated before it is used.

Typical validation includes:

* Required values exist.
* Directory paths are valid.
* Configuration format is correct.
* Runtime values are internally consistent.

Invalid configuration should produce clear error messages and prevent further execution.

---

## Best Practices

To ensure a stable development environment:

* Keep a single `mdw.json` for each workspace.
* Do not hardcode paths in commands or services.
* Modify configuration through supported mechanisms.
* Validate configuration after significant changes.
* Keep generated directories outside the toolkit source directory.

Following these practices helps maintain a clean, consistent, and reproducible development environment.

