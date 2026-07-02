# Command Line Interface (CLI)

## Overview

MDW provides a unified command-line interface designed to simplify and standardize WordPress plugin development workflows.

Every command follows the same conventions, output style, and execution model, allowing developers to work efficiently without learning different behaviors for different commands.

The CLI is intentionally designed to be predictable, lightweight, and production-oriented.

---

## CLI Philosophy

The MDW CLI is built around a few core principles:

### Consistency

Commands should behave consistently across the entire toolkit.

Users should always know what to expect regardless of which command is executed.

### Simplicity

Commands should be easy to understand and require minimal memorization.

The command structure favors clarity over unnecessary abbreviations or aliases.

### Predictability

A command should always produce consistent results when executed under the same conditions.

Unexpected side effects should be avoided.

### Reliability

Commands should validate their environment before performing critical operations.

Potential problems should be detected as early as possible.

### Reusability

Commands should delegate business logic to shared services instead of implementing duplicate functionality.

---

## Command Naming

Commands use simple, descriptive names.

Examples include:

```text
mdw doctor
mdw check
mdw build
mdw zip
mdw release
```

Command names are intended to be self-explanatory and closely aligned with their primary responsibility.

---

## Command Structure

All commands follow the same general syntax.

```text
mdw <command> [options]
```

This consistent structure makes the CLI easier to learn and simplifies future expansion while maintaining backward compatibility.

## Command Discovery

MDW is designed to make command discovery simple and intuitive.

The main command provides access to the available functionality, while individual commands expose their own help and usage information when appropriate.

Users should not be required to remember complex command hierarchies or hidden options.

---

## Global Behavior

All commands follow the same execution model.

A typical command performs the following steps:

1. Initialize the runtime environment.
2. Load the configuration.
3. Validate the workspace.
4. Validate user input.
5. Execute the requested operation.
6. Display the result.
7. Exit gracefully.

Commands should not modify the workspace unless the requested operation requires it.

---

## Output Standards

Every command should produce output that is:

* Clear
* Consistent
* Readable
* Actionable

Whenever possible, output should explain:

* What is happening.
* Whether the operation succeeded.
* If a problem occurred.
* What the user should do next.

Internal implementation details should not be exposed to the user.

---

## Exit Behavior

Commands should terminate cleanly regardless of the outcome.

On successful completion:

* Exit without unnecessary output.
* Return a success exit code.
* Leave the workspace in a consistent state.

If an error occurs:

* Stop execution safely.
* Display a meaningful error message.
* Avoid partial or inconsistent operations.
* Return an appropriate exit code when applicable.

---

## Logging Philosophy

MDW uses user-focused console output.

Messages should be:

* Informative
* Concise
* Consistent

Diagnostic information should assist troubleshooting without overwhelming the user.

## Error Messages

Error messages should help users understand and resolve problems quickly.

Every error message should:

* Clearly describe the problem.
* Avoid technical jargon whenever possible.
* Suggest the next action when appropriate.
* Remain consistent with the rest of the CLI.

Examples:

```text
ERROR: Workspace could not be detected.

Run 'mdw doctor' to diagnose your environment.
```

```text
ERROR: Plugin validation failed.

Run 'mdw plugin-check' for detailed validation results.
```

The objective is to guide users toward a solution rather than simply reporting that something failed.

---

## Best Practices

To get the most out of MDW, the following practices are recommended:

* Keep all projects inside a single MDW workspace.
* Validate your environment before starting development.
* Run project validation before every build.
* Use the Release Pipeline instead of manual packaging.
* Commit changes frequently using Git.
* Keep documentation up to date.
* Execute the automated test suite before publishing a release.
* Avoid modifying generated build or release artifacts directly.

Following these practices helps ensure a consistent and reliable development workflow.

---

## CLI Summary

The MDW command-line interface is designed around consistency, simplicity, and reliability.

Every command follows the same lifecycle, uses the same configuration system, and relies on shared services. This architecture reduces complexity while providing a predictable experience across the entire toolkit.

The CLI is intentionally stable and conservative. Future improvements should enhance usability without changing the established command model or breaking backward compatibility.
