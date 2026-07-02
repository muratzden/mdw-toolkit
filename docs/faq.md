# Frequently Asked Questions (FAQ)

## What is MDW?

MDW is a command-line toolkit that standardizes the development workflow for WordPress plugins on Windows.

---

## Who is MDW designed for?

MDW is intended for developers who build and maintain WordPress plugins and want a consistent, automated, and production-ready development workflow.

---

## Which operating systems are supported?

MDW currently supports:

* Windows 10
* Windows 11

---

## Which PowerShell versions are supported?

MDW supports:

* Windows PowerShell 5.1
* PowerShell 7+

---

## Does MDW support WordPress themes?

No.

MDW is designed specifically for WordPress plugin development.

---

## Can I use my existing projects?

Yes.

Existing WordPress plugin projects can be organized inside the recommended MDW workspace structure.

---

## Does MDW modify my source project?

No.

MDW generates build and release artifacts separately from the original source code.

The source project remains unchanged.

---

## Where are build files stored?

Production builds are generated in the configured **Build** directory.

---

## Where are release packages stored?

Release packages are generated in the configured **Releases** directory.

---

## Where are backups stored?

Backups are stored in the configured **Backups** directory.

---

## Why doesn't MDW package the source directory directly?

Packaging the source directory may accidentally include development files, temporary files, or local configuration.

MDW always packages a validated production build instead.

---

## How do I verify my environment?

Run:

```powershell
mdw doctor
```

---

## How do I validate my plugin?

Run:

```powershell
mdw plugin-check
```

---

## How do I create a release?

Run:

```powershell
mdw release
```

The Release Pipeline performs validation, backup, build, packaging, and verification automatically.

---

## How do I report a bug?

Please create a GitHub Issue and include:

* MDW version
* PowerShell version
* Windows version
* Steps to reproduce
* Expected behavior
* Actual behavior

---

## How do I report a security issue?

Please follow the instructions provided in **SECURITY.md**.

Do not report security vulnerabilities through public GitHub Issues.

