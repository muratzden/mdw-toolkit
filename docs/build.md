# Build Pipeline

## Overview

The Build Pipeline is responsible for creating a clean, production-ready version of a WordPress plugin.

Instead of packaging the original source directory, MDW generates a dedicated build that contains only the files required for distribution.

This approach ensures that development artifacts, temporary files, and unnecessary resources are excluded from production packages.

---

## Build Objectives

The Build Pipeline is designed to:

* Produce clean production builds.
* Generate repeatable build output.
* Exclude development-only files.
* Preserve the original source project.
* Prepare artifacts for ZIP packaging.
* Support automated release workflows.

---

## Build Process

A typical build operation follows these steps:

```text
Validate Workspace
        │
        ▼
Validate Plugin
        │
        ▼
Prepare Build Directory
        │
        ▼
Copy Production Files
        │
        ▼
Exclude Development Files
        │
        ▼
Verify Build Output
        │
        ▼
Build Complete
```

Each step is executed in a controlled sequence to ensure a reliable and reproducible build.

---

## Build Principles

The Build Pipeline follows several core principles:

* Never modify the source project.
* Always generate a new build.
* Keep builds isolated from source code.
* Produce deterministic output whenever possible.
* Fail immediately if validation detects an error.

These principles help ensure that every build is suitable for packaging and release.

## Build Directory

All build artifacts are generated inside the configured build directory.

The build directory is temporary by design and should contain only production-ready output.

Developers should never edit files directly inside the build directory.

Any required changes should be made in the source project before generating a new build.

---

## File Inclusion

Only files required for production should be included in the build.

Typical examples include:

* Plugin source code
* Assets required at runtime
* Language files
* Documentation intended for distribution
* License information

The exact inclusion rules are defined by the build process.

---

## File Exclusion

Development-only resources should be excluded from production builds.

Examples include:

* Version control metadata
* Development scripts
* Test files
* Temporary files
* IDE configuration files
* Local development resources

Excluding unnecessary files results in smaller, cleaner, and more secure release packages.

---

## Build Validation

Before the build is considered complete, MDW performs a final verification of the generated output.

Validation typically confirms:

* Required files exist.
* Directory structure is correct.
* Build completed successfully.
* Output is suitable for packaging.

If validation fails, the build should not proceed to the packaging stage.

---

## Build Summary

The Build Pipeline transforms a development project into a clean production artifact.

By separating source code from generated output and applying consistent inclusion and exclusion rules, MDW ensures that every build is predictable, reproducible, and ready for the next stage of the release process.
