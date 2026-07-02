# Testing

## Overview

Testing is an essential part of the MDW development lifecycle.

Every change should be verified to ensure existing functionality continues to work as expected. The goal of the testing process is to maintain a stable, reliable, and production-ready toolkit.

MDW combines automated testing with manual verification to validate both functionality and user experience.

---

## Testing Goals

The testing strategy is designed to:

* Verify core functionality.
* Detect regressions early.
* Maintain backward compatibility.
* Validate production workflows.
* Improve release reliability.

Testing should be performed throughout development, not only before a release.

---

## Automated Testing

MDW includes an automated test suite that verifies the core components of the toolkit.

Run the test suite from the project root:

```powershell
.\tests\run-tests.ps1
```

Expected result:

```text
Total: 38
Passed: 38
Failed: 0
Warnings: 0
```

Any failed test should be investigated before additional development continues.

---

## Test Coverage

The automated test suite validates:

* CLI Foundation
* Command Router
* Command Registry
* Services Layer
* Validators
* Workspace Intelligence
* Configuration
* Build Pipeline
* ZIP Pipeline
* Release Pipeline
* Git integration
* LocalWP integration

Each release should maintain or improve the current level of test coverage.

## Regression Testing

Regression testing ensures that previously working functionality continues to behave correctly after changes are introduced.

Before every release, verify:

* All automated tests pass.
* Existing commands behave consistently.
* Build output is unchanged unless intentionally modified.
* Release packages are generated successfully.
* Workspace validation completes without errors.

---

## Manual Verification

In addition to automated tests, the following manual checks are recommended:

* Run `mdw doctor`.
* Validate a sample plugin.
* Generate a production build.
* Create a ZIP package.
* Execute the full release pipeline.
* Review generated artifacts.

Manual verification complements automated testing by confirming the complete user workflow.

---

## Release Checklist

Before publishing a new version:

* All automated tests pass.
* No known critical issues remain.
* Documentation is up to date.
* CHANGELOG has been updated.
* Release artifacts have been verified.
* Git repository is in a clean state.

---

## Testing Principles

MDW follows these testing principles:

* Test early.
* Test often.
* Automate whenever practical.
* Prevent regressions.
* Keep releases reproducible.
* Never publish unverified builds.

---

## Testing Summary

A reliable testing process is fundamental to the long-term stability of MDW.

By combining automated tests, regression testing, and manual verification, every release is validated before distribution, helping ensure a consistent and dependable development experience.

