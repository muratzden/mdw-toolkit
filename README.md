# MDW Toolkit

> **Professional CLI Toolkit for WordPress Plugin Development**

Build, validate, test and release WordPress plugins from a standardized development workspace.

MDW Toolkit helps WordPress developers automate repetitive tasks, improve code quality and streamline the complete plugin development lifecycle—from project creation to WordPress.org release.

---

## Features

- Professional WordPress plugin scaffolding
- Standardized development workspace
- Plugin health checks
- Environment diagnostics
- Automated validation
- Integrated testing
- Build automation
- ZIP package generation
- Release pipeline
- Workspace Intelligence
- WordPress.org workflow support

---

## Why MDW Toolkit?

Developing WordPress plugins often involves repetitive manual steps.

MDW Toolkit automates the entire workflow so you can focus on writing code instead of managing files, folders and release processes.

**Benefits**

- Faster development
- Consistent project structure
- Repeatable releases
- Reduced human error
- Better code quality
- WordPress.org friendly workflow

---

# Installation

```powershell
git clone https://github.com/muratzden/mdw-toolkit.git

cd mdw-toolkit
```

---

# Quick Start

Create a new plugin

```powershell
mdw new my-plugin
```

Run diagnostics

```powershell
mdw doctor
```

Validate the plugin

```powershell
mdw check my-plugin
```

Run tests

```powershell
mdw test my-plugin
```

Build

```powershell
mdw build my-plugin
```

Create ZIP

```powershell
mdw zip my-plugin
```

Release

```powershell
mdw release my-plugin
```

---

# Available Commands

| Command | Description |
|----------|-------------|
| new | Create a new plugin |
| init | Initialize an existing plugin |
| doctor | Check development environment |
| info | Display workspace information |
| check | Validate plugin structure |
| plugin-check | Run WordPress Plugin Check |
| test | Execute automated tests |
| build | Build production package |
| zip | Generate release ZIP |
| release | Complete release workflow |

---

# Typical Workflow

```
Create Plugin
      │
      ▼
Develop
      │
      ▼
Validate
      │
      ▼
Test
      │
      ▼
Build
      │
      ▼
ZIP
      │
      ▼
Release
```

---

# Project Structure

```
mdw-toolkit/

├── commands/
├── core/
├── services/
├── validators/
├── tests/
├── scripts/
├── docs/
└── templates/
```

---

# Philosophy

MDW Toolkit is built around a few simple principles.

- Automation First
- One Standard Workspace
- WordPress Best Practices
- Repeatable Builds
- Clean Architecture
- Developer Productivity

---

# Current Status

Current Version

**0.1.2-alpha**

Project Status

**Alpha**

The project is under active development and APIs may change before the first stable release.

---

# Roadmap

- Workspace Automation
- Advanced Validators
- Plugin Templates
- CI/CD Integration
- Marketplace Support
- Multi-project Management

See **ROADMAP.md** for details.

---

# Contributing

Contributions are welcome.

Please read **CONTRIBUTING.md** before submitting pull requests.

---

# License

This project is licensed under the MIT License.

See **LICENSE** for details.

---

# Author

**Murat Özden**

GitHub:
https://github.com/muratzden

---
