# Contributing

First of all, thank you for your interest in contributing to MDW.

The goal of this project is to provide a stable, maintainable, and production-ready development toolkit for WordPress plugin development. Every contribution should support that goal.

---

# Before You Start

Please read the project documentation before making changes.

Important documents include:

* README.md
* CHANGELOG.md
* SECURITY.md
* CODE_OF_CONDUCT.md
* Documentation in the `docs` directory

---

# Development Principles

Contributions should follow the existing project architecture.

Please do not introduce unnecessary complexity or duplicate existing functionality.

Core principles include:

* Keep the architecture modular.
* Reuse existing services whenever possible.
* Avoid code duplication.
* Keep functions focused on a single responsibility.
* Maintain PowerShell 5.1 and PowerShell 7 compatibility.
* Preserve backward compatibility unless a breaking change is explicitly planned.

---

# Coding Standards

Please ensure that your code:

* follows the existing coding style
* uses meaningful names
* includes appropriate comments where necessary
* avoids dead code
* avoids legacy helper patterns
* remains easy to maintain

---

# Testing

Before submitting a contribution:

* Run the complete test suite.
* Verify that all existing commands continue to work.
* Ensure no regressions have been introduced.

Expected result:

```text
Total: 38
Passed: 38
Failed: 0
Warnings: 0
```

---

# Documentation

If your contribution changes behavior, update the relevant documentation.

This may include:

* README
* CHANGELOG
* docs/
* command documentation

---

# Pull Requests

Before opening a Pull Request:

* Ensure your branch is up to date.
* Keep changes focused on a single topic.
* Write clear commit messages.
* Include documentation updates when appropriate.
* Verify all tests pass.

Large architectural changes should be discussed through a GitHub Issue before implementation.

---

# Reporting Issues

When reporting a bug, please include:

* MDW version
* PowerShell version
* Windows version
* Steps to reproduce
* Expected behavior
* Actual behavior
* Relevant logs or screenshots

---

# Questions

If you have questions about the project, please use GitHub Discussions or open an Issue.

---

# Thank You

Every contribution, whether it is code, documentation, testing, or feedback, helps improve MDW.

Thank you for helping make the project better.
