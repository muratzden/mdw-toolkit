# Architecture

## Overview

MDW is built around a modular and service-oriented architecture designed to provide a consistent, maintainable, and production-ready command-line experience for WordPress plugin development.

Rather than implementing command-specific logic in individual scripts, MDW separates responsibilities into dedicated layers. Each layer has a single responsibility and communicates through well-defined interfaces.

The architecture emphasizes:

* Separation of concerns
* Code reuse
* Predictable command behavior
* Centralized configuration
* Production reliability
* Long-term maintainability

This design allows new commands and internal improvements to be implemented without affecting the overall structure of the toolkit.

---

## Design Goals

The architecture of MDW was designed with the following goals:

* Keep the CLI simple and predictable.
* Centralize shared functionality.
* Eliminate duplicated logic.
* Isolate business logic from command implementations.
* Provide a single configuration source.
* Support both Windows PowerShell 5.1 and PowerShell 7.
* Maintain a clean and extensible codebase.

---

## Core Principles

### Modular Design

Every major responsibility is implemented as an independent module.

### Single Responsibility

Each component performs one well-defined task.

### Shared Services

Common functionality is implemented once and reused across commands.

### Consistent User Experience

All commands follow the same execution flow, output format, and error handling strategy.

### Production First

MDW prioritizes reliability, stability, and maintainability over unnecessary complexity.

## System Architecture

MDW follows a layered architecture where each layer has a clearly defined responsibility. Commands do not directly implement business logic; instead, they delegate operations to shared services and supporting components.

```text
                   +-------------------+
                   |      mdw.ps1      |
                   +---------+---------+
                             |
                             ▼
                   +-------------------+
                   |   Bootstrap       |
                   +---------+---------+
                             |
                             ▼
                   +-------------------+
                   | Command Router    |
                   +---------+---------+
                             |
                             ▼
                   +-------------------+
                   | Command Registry  |
                   +---------+---------+
                             |
         +-------------------+-------------------+
         |                   |                   |
         ▼                   ▼                   ▼
    Commands           Validators          Services
         |                                       |
         +-------------------+-------------------+
                             |
                             ▼
              Workspace, Build & Release Pipelines
```

The execution flow always follows the same path regardless of which command is invoked. This consistency simplifies maintenance and reduces the likelihood of unexpected behavior.

---

## Layer Responsibilities

### CLI Foundation

The CLI Foundation serves as the application's entry point. It initializes the runtime environment, loads required modules, and starts the command execution process.

### Bootstrap

The Bootstrap component prepares the execution environment by loading configuration, shared functions, and core services before any command is executed.

### Command Router

The Command Router interprets user input and forwards execution to the appropriate registered command. It acts as the central dispatcher for the CLI.

### Command Registry

The Command Registry maintains a centralized list of all available commands and their metadata. This eliminates hardcoded routing logic and makes the CLI easier to maintain.

### Commands

Commands provide the user-facing interface of MDW. Their primary responsibility is to validate input, call the appropriate services, and present the results. Business logic should remain outside command implementations.

### Services

The Services layer contains reusable business logic shared by multiple commands. Centralizing this logic minimizes duplication and ensures consistent behavior throughout the toolkit.

### Validators

Validators verify the integrity of the workspace, configuration, environment, and plugin structure before critical operations are executed.

Each layer has a single responsibility, making the overall architecture easier to understand, test, and maintain.

## Workspace Intelligence

Workspace Intelligence is responsible for identifying, validating, and managing the active MDW workspace.

Rather than relying on hardcoded paths or command-specific assumptions, all workspace operations are resolved through a centralized mechanism.

Its responsibilities include:

* Detecting the active workspace
* Resolving configured paths
* Validating the workspace structure
* Providing shared path information to all services
* Ensuring consistent behavior across commands

This approach guarantees that every command operates on the same workspace definition and eliminates inconsistencies caused by duplicated path resolution logic.

---

## Configuration Layer

All runtime configuration is managed through a centralized configuration layer.

The configuration system provides:

* Workspace metadata
* Directory locations
* Runtime settings
* Version information

Commands never access configuration files directly. Instead, they retrieve configuration values through the shared configuration service.

This design reduces coupling and keeps configuration management consistent throughout the application.

---

## Build Pipeline

The Build Pipeline prepares a clean production-ready copy of a plugin.

Typical responsibilities include:

* Validating the project
* Preparing the build directory
* Removing development artifacts
* Copying production files
* Verifying the generated output

The pipeline is deterministic, meaning identical inputs produce identical build outputs.

---

## ZIP Pipeline

The ZIP Pipeline packages the generated build into a distributable archive.

Its responsibilities include:

* Validating build output
* Creating a release archive
* Preserving directory structure
* Producing reproducible ZIP packages

The pipeline operates only on build artifacts and never packages the original source directory directly.

---

## Release Pipeline

The Release Pipeline orchestrates the complete release process.

A typical execution flow is:

```text
Workspace Validation
        │
        ▼
Project Validation
        │
        ▼
Backup
        │
        ▼
Build
        │
        ▼
ZIP
        │
        ▼
Release Complete
```

By combining multiple operations into a single controlled workflow, the Release Pipeline reduces manual work and ensures every release follows the same validated process.

## Directory Structure

MDW organizes its source code into logical modules, each with a specific responsibility.

```text
mdw-toolkit/
│
├── commands/
├── core/
├── services/
├── validators/
├── tests/
├── docs/
├── scripts/
├── mdw.json
└── mdw.ps1
```

### Directory Responsibilities

| Directory    | Responsibility                                |
| ------------ | --------------------------------------------- |
| `commands`   | User-facing CLI commands                      |
| `core`       | Core framework and application bootstrap      |
| `services`   | Shared business logic                         |
| `validators` | Environment, workspace, and plugin validation |
| `tests`      | Automated test suite                          |
| `docs`       | Project documentation                         |
| `scripts`    | Development and maintenance scripts           |

Each directory has a well-defined purpose. Cross-layer dependencies should be kept to a minimum.

---

## Execution Flow

Every MDW command follows the same execution lifecycle.

```text
User Command
      │
      ▼
Bootstrap
      │
      ▼
Load Configuration
      │
      ▼
Resolve Command
      │
      ▼
Validate Environment
      │
      ▼
Execute Service
      │
      ▼
Display Result
      │
      ▼
Exit
```

This predictable lifecycle simplifies debugging, improves consistency, and reduces maintenance costs.

---

## Error Handling

MDW uses a centralized error handling strategy.

The main principles are:

* Validate early.
* Fail fast.
* Display clear error messages.
* Avoid exposing internal implementation details.
* Return consistent exit codes where appropriate.
* Keep command output readable and actionable.

Commands should report errors without leaving the workspace in an inconsistent state.

---

## Compatibility

MDW is designed to maintain broad compatibility across supported environments.

### Operating Systems

* Windows 10
* Windows 11

### PowerShell

* Windows PowerShell 5.1
* PowerShell 7+

### Development Environment

* Git for Windows
* LocalWP (recommended)
* Standard WordPress plugin development workflow

Backward compatibility is preserved whenever possible to ensure a stable experience across releases.

## Architecture Decisions

The current architecture is the result of a deliberate effort to prioritize stability, maintainability, and consistency over unnecessary complexity.

### Centralized Configuration

All configuration is managed through a single configuration layer.

This ensures that every command and service uses the same runtime settings and workspace information.

### Shared Services

Business logic is implemented once and shared across the application.

This minimizes duplicated code and ensures that common operations behave consistently.

### Modular Commands

Commands are intentionally lightweight.

Their responsibilities are limited to:

* Receiving user input
* Validating arguments
* Calling the appropriate services
* Displaying results

Business logic should remain within the Services layer.

### Predictable Execution

Every command follows the same execution lifecycle.

A consistent execution model simplifies maintenance, testing, debugging, and future development.

### Production-Oriented Design

MDW is designed primarily as a production development tool.

Architectural decisions favor reliability, repeatability, and long-term maintainability rather than experimental features.

---

## Architecture Summary

MDW is built on a layered architecture that separates responsibilities into independent, reusable components.

By combining a centralized configuration system, modular commands, shared services, and standardized execution pipelines, the toolkit provides a consistent and reliable development experience for WordPress plugin projects.

The architecture is intentionally conservative. New functionality should integrate with the existing design rather than introducing parallel systems or bypassing established layers.

Maintaining a clean architecture is considered essential to the long-term success of the project.
