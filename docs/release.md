# Release Pipeline

## Overview

The Release Pipeline is responsible for producing a complete, validated, and distributable release package.

Rather than executing individual tasks manually, MDW combines validation, backup, build, and packaging into a single, standardized workflow.

This approach reduces manual work, minimizes human error, and ensures that every release follows the same production process.

---

## Release Objectives

The Release Pipeline is designed to:

* Validate the development environment.
* Verify the active project.
* Create a backup before release.
* Generate a clean production build.
* Create a distributable ZIP package.
* Produce repeatable release artifacts.

---

## Release Workflow

A typical release follows this sequence:

```text
Workspace Validation
        │
        ▼
Project Validation
        │
        ▼
Create Backup
        │
        ▼
Build Project
        │
        ▼
Generate ZIP Package
        │
        ▼
Verify Release Output
        │
        ▼
Release Complete
```

Each stage must complete successfully before the next stage begins.

---

## Release Principles

The Release Pipeline follows these core principles:

* Validate before making changes.
* Create a backup before building.
* Never package the source directory directly.
* Generate releases from build artifacts only.
* Stop immediately if a critical error occurs.
* Produce consistent and reproducible release packages.

These principles help ensure that every release is suitable for production and can be reproduced reliably.

## Release Validation

Before a release is finalized, MDW performs a final validation of the generated artifacts.

Typical validation includes:

* Workspace integrity
* Plugin validation
* Build verification
* ZIP package verification
* Release directory validation

A release should never be published if any validation step fails.

---

## Release Artifacts

A successful release typically produces:

* Clean production build
* Distribution ZIP package
* Updated release metadata
* Backup of the source project

These artifacts are stored in their configured workspace locations and remain separated from the original source code.

---

## Release Best Practices

For reliable releases, it is recommended to:

* Run `mdw doctor` before creating a release.
* Validate the project with `mdw check`.
* Execute `mdw plugin-check` before packaging.
* Ensure all automated tests pass.
* Review the generated ZIP package before distribution.
* Tag releases in Git after successful validation.

Following these practices helps maintain consistent release quality.

---

## Release Summary

The Release Pipeline represents the final stage of the MDW development workflow.

By combining validation, backup, build, packaging, and verification into a single automated process, MDW delivers reliable, repeatable, and production-ready releases while protecting the integrity of the source project.
