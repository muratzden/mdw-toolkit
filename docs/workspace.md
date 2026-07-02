# Workspace

## Overview

MDW is designed around a standardized workspace model.

Instead of managing each plugin independently, all projects are organized within a single workspace. This provides a consistent development experience and simplifies validation, build, backup, and release operations.

A standardized workspace is one of the core design principles of MDW.

---

## Recommended Workspace Layout

```text
C:\Workspace\
│
├── mdw-toolkit\
│
├── Plugins\
│   ├── plugin-one\
│   ├── plugin-two\
│   └── ...
│
├── Build\
│
├── Releases\
│
└── Backups\
```

---

## Directory Responsibilities

### mdw-toolkit

Contains the MDW source code and CLI.

This directory should contain only the toolkit itself and should not be used for plugin development.

---

### Plugins

Contains all WordPress plugin projects managed by MDW.

Each plugin should reside in its own directory.

---

### Build

Contains temporary production builds.

Build artifacts should be treated as generated files and should not be edited manually.

---

### Releases

Contains generated release packages.

These packages are intended for distribution and publication.

---

### Backups

Contains automatically generated project backups.

Backups should be retained independently from the source projects and reviewed periodically according to your backup strategy.

## Workspace Lifecycle

The workspace is created once and reused throughout the entire development lifecycle.

A typical workflow is:

```text
Create Workspace
        │
        ▼
Create Plugin
        │
        ▼
Develop
        │
        ▼
Validate
        │
        ▼
Build
        │
        ▼
Package
        │
        ▼
Release
        │
        ▼
Maintain
```

All projects within the workspace follow the same lifecycle and directory conventions.

---

## Workspace Rules

To maintain a consistent development environment, the following rules should be observed:

* Use a single workspace for all projects.
* Keep plugin source code inside the `Plugins` directory.
* Do not modify generated files inside the `Build` directory.
* Store release packages only in the `Releases` directory.
* Keep backups separate from source code.
* Avoid creating custom directory structures outside the standard workspace layout.

Following these rules helps ensure that all MDW commands behave consistently.

---

## Workspace Isolation

MDW separates source code from generated artifacts.

| Type             | Location   |
| ---------------- | ---------- |
| Source Code      | `Plugins`  |
| Build Output     | `Build`    |
| Release Packages | `Releases` |
| Backups          | `Backups`  |

This separation reduces the risk of accidental modifications and keeps repositories clean.

---

## Workspace Validation

Many MDW commands verify the workspace before execution.

Validation may include:

* Workspace structure
* Required directories
* Configuration consistency
* Project accessibility

If validation fails, the command stops before performing any changes.

This approach helps prevent invalid builds and incomplete release operations.

## Workspace Best Practices

The following recommendations help maintain a clean, stable, and predictable development environment.

### Use a Single Workspace

Keep all WordPress plugin projects inside the same MDW workspace.

This provides a consistent development experience and allows all commands to operate on a standardized directory structure.

---

### Keep Source Code Clean

Only source files should exist inside plugin directories.

Do not store:

* Build artifacts
* Release packages
* Temporary files
* Backup copies

inside source projects.

---

### Do Not Edit Generated Files

The `Build` and `Releases` directories contain generated output.

If changes are required, modify the source project and regenerate the build rather than editing generated files directly.

---

### Keep Backups

Backups should be created regularly and stored independently from active development projects.

A reliable backup strategy protects against accidental data loss during development and release operations.

---

## Common Mistakes

Avoid the following practices:

* Developing directly inside generated build directories.
* Publishing manually modified ZIP packages.
* Mixing source code with generated artifacts.
* Maintaining multiple workspace layouts for different projects.
* Hardcoding workspace paths in scripts.

Following the recommended workspace model helps ensure consistent and repeatable results.

---

## Workspace Summary

The workspace is the foundation of MDW.

A standardized directory structure, centralized configuration, and clear separation between source code and generated artifacts allow every command to operate consistently across all projects.

Maintaining a clean workspace improves reliability, simplifies maintenance, and supports reproducible build and release processes.
