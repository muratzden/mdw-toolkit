# Commands Reference

## Overview

This document provides a complete reference for all MDW commands.

Each command follows the same execution model and is designed to perform a single, well-defined task.

---

## Available Commands

| Command            | Description                                    |
| ------------------ | ---------------------------------------------- |
| `mdw`              | Display the main CLI interface.                |
| `mdw version`      | Display the installed MDW version.             |
| `mdw info`         | Display workspace and environment information. |
| `mdw doctor`       | Diagnose the development environment.          |
| `mdw check`        | Validate the current workspace.                |
| `mdw plugin-check` | Validate the active WordPress plugin.          |
| `mdw build`        | Create a production build.                     |
| `mdw zip`          | Generate a release ZIP package.                |
| `mdw release`      | Execute the complete release workflow.         |
| `mdw git`          | Execute Git-related operations.                |
| `mdw local`        | Execute LocalWP-related operations.            |
| `mdw backup`       | Create a workspace backup.                     |
| `mdw clean`        | Remove generated build artifacts.              |

---

## Command Categories

### Information

* version
* info

### Diagnostics

* doctor
* check
* plugin-check

### Build & Release

* build
* zip
* release

### Workspace

* backup
* clean

### Integration

* git
* local

## Command Reference

### `mdw`

Displays the main MDW command-line interface.

**Usage**

```powershell
mdw
```

---

### `mdw version`

Displays the installed MDW version.

**Usage**

```powershell
mdw version
```

---

### `mdw info`

Displays information about the current workspace and runtime environment.

**Usage**

```powershell
mdw info
```

---

### `mdw doctor`

Performs diagnostic checks on the development environment.

Checks may include:

* Workspace validation
* Configuration validation
* Runtime verification
* Environment diagnostics

**Usage**

```powershell
mdw doctor
```

---

### `mdw check`

Validates the active workspace before build or release operations.

**Usage**

```powershell
mdw check
```

---

### `mdw plugin-check`

Validates the active WordPress plugin.

This command should be executed before creating production builds.

**Usage**

```powershell
mdw plugin-check
```

---

### `mdw build`

Creates a clean production build.

**Usage**

```powershell
mdw build
```

---

### `mdw zip`

Creates a production-ready ZIP package from the latest build.

**Usage**

```powershell
mdw zip
```

---

### `mdw release`

Runs the complete release pipeline.

Typical workflow:

```text
Validate
    ↓
Backup
    ↓
Build
    ↓
ZIP
    ↓
Release
```

**Usage**

```powershell
mdw release
```

---

### `mdw git`

Provides Git-related operations.

**Usage**

```powershell
mdw git
```

---

### `mdw local`

Provides LocalWP integration commands.

**Usage**

```powershell
mdw local
```

---

### `mdw backup`

Creates a backup of the active project or workspace.

**Usage**

```powershell
mdw backup
```

---

### `mdw clean`

Removes generated build artifacts while preserving source files.

**Usage**

```powershell
mdw clean
```

## Common Workflows

The following examples demonstrate the recommended way to use MDW during everyday development.

---

### Daily Development

Before starting development, verify that your environment is healthy.

```powershell id="1l74bb"
mdw doctor
```

Validate the current project.

```powershell id="x5sf8t"
mdw check
```

Develop and test your plugin locally.

---

### Preparing a Production Build

Before creating a release package, validate the plugin.

```powershell id="ldnlme"
mdw plugin-check
```

Generate a production build.

```powershell id="xhgr7o"
mdw build
```

Create the distribution package.

```powershell id="y6tn6i"
mdw zip
```

---

### Publishing a Release

Execute the complete release workflow.

```powershell id="cfkvsp"
mdw release
```

The release pipeline performs all required steps in the correct order, ensuring consistent and repeatable releases.

---

## Recommended Workflow

```text id="92lmoj"
mdw doctor
      │
      ▼
mdw check
      │
      ▼
Development
      │
      ▼
mdw plugin-check
      │
      ▼
mdw build
      │
      ▼
mdw zip
      │
      ▼
mdw release
```

---

## Commands Summary

MDW commands are designed to work together as part of a single, standardized development workflow.

Rather than treating each command as an isolated utility, MDW encourages a consistent sequence of validation, build, packaging, and release operations. This approach improves reliability, reduces manual work, and helps maintain a clean and predictable development process across all projects.
