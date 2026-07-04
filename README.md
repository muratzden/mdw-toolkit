# MDW Toolkit

Professional WordPress CLI Toolkit for building, validating, testing and releasing WordPress plugins.

MDW Toolkit is a production-ready PowerShell CLI for a standardized WordPress plugin workspace. It helps developers create plugins, validate project structure, run PHP lint checks, run compliance checks, run internal and WP-CLI plugin checks, build production packages, create ZIP releases, manage backups, inspect Git state and work with LocalWP.

## Current Release

v1.1.0 Stable

## Requirements

- Windows
- PowerShell 5.1 or PowerShell 7+
- Git
- PHP 7.4 or newer for linting
- WP-CLI for WordPress Plugin Check integration
- SVN and Composer are recommended for WordPress.org workflows
- LocalWP is optional

## Installation

```powershell
git clone https://github.com/muratzden/mdw-toolkit.git C:\Workspace\mdw-toolkit
Set-Location C:\Workspace\mdw-toolkit
.\install.ps1
mdw version
```

## Workspace Structure

```text
C:\Workspace
|-- Build
|-- Plugins
|   |-- my-plugin
|-- Releases
|-- mdw-toolkit

D:\Workspace Backup
|-- my-plugin
```

Paths are managed through `mdw.json`.

## Features

- Command router and command registry
- Centralized `mdw.json` configuration
- Workspace path service
- Shared CLI output helpers
- Doctor environment diagnostics
- Plugin structure validation
- PHP syntax linting with `php -l`
- Internal plugin check suite
- WordPress compliance foundation checks
- Compliance prefix validation for WordPress-safe identifiers
- WP-CLI WordPress Plugin Check integration
- Build pipeline with production exclusions
- ZIP generation with correct `plugin-slug/` package root
- Release preparation pipeline
- Backup and clean commands
- Git repository inspection
- LocalWP detection and deployment support
- Automated test runner

## Commands

| Command | Description |
| --- | --- |
| `mdw` | Show the home screen |
| `mdw help` | Show command overview |
| `mdw help <command>` | Show command-specific help |
| `mdw version` | Show toolkit version |
| `mdw info` | Show workspace information |
| `mdw doctor` | Check local development environment |
| `mdw check <plugin>` | Run quick internal plugin checks |
| `mdw lint <plugin>` | Run PHP syntax lint checks |
| `mdw plugin-check <plugin>` | Run internal plugin check |
| `mdw compliance <plugin>` | Run WordPress compliance foundation checks |
| `mdw plugin-check -PluginSlug <plugin> -WordPressPath <path>` | Run WP-CLI Plugin Check in a test WordPress install |
| `mdw validate <plugin>` | Validate mdw.json, headers, readme and Git state |
| `mdw build <plugin>` | Build production plugin files |
| `mdw zip <plugin>` | Create release ZIP |
| `mdw release <plugin>` | Run backup, build, validate and ZIP pipeline |
| `mdw backup <plugin>` | Create plugin backup |
| `mdw clean <plugin>` | Clean build and release outputs |
| `mdw git` | Show Git repository status |
| `mdw local` | Show LocalWP environment status |
| `mdw new plugin <plugin-slug>` | Create a new plugin scaffold |
| `mdw init plugin <source-path> <plugin-slug>` | Import an existing plugin |
| `mdw test` | Run MDW automated tests |

## Examples

```powershell
mdw doctor
mdw help build
mdw new plugin my-plugin
mdw validate my-plugin
mdw lint my-plugin
mdw plugin-check my-plugin
mdw compliance my-plugin
mdw compliance my-plugin --prefix craftcommercekit_reviewflow_
mdw build my-plugin
mdw zip my-plugin
mdw release my-plugin
```

WP-CLI Plugin Check example:

```powershell
mdw plugin-check -PluginSlug my-plugin -WordPressPath C:\laragon\www\wp-test
```

If the WP-CLI Plugin Check command is missing, install it inside the test WordPress site:

```powershell
wp plugin install plugin-check --activate
```

## Build Exclusions

Production builds exclude development and repository files, including:

```text
.git
.github
.gitignore
.gitattributes
.vscode
.idea
node_modules
vendor
vendor/bin
tests
docs
README.md
PROJECT.md
CHANGELOG.md
CONTRIBUTING.md
ROADMAP.md
composer.lock
phpunit.xml
phpunit.xml.dist
*.zip
.DS_Store
Thumbs.db
Desktop.ini
```

## Release Workflow

```text
backup
build
validate
zip
release complete
```

The release pipeline stops when validation fails or the ZIP package cannot be created.

## Screenshots

Screenshots are available in `assets/screenshots/`.

## Demo

Demo media is available in `assets/demo/`.

## Documentation

Additional documentation is available in `docs/`:

- `docs/architecture.md`
- `docs/cli.md`
- `docs/commands.md`
- `docs/configuration.md`
- `docs/workspace.md`
- `docs/build.md`
- `docs/release.md`
- `docs/testing.md`
- `docs/faq.md`
- `docs/roadmap.md`

## Repository Readiness

This repository includes:

- README
- LICENSE
- CHANGELOG
- CONTRIBUTING
- CODE_OF_CONDUCT
- SECURITY
- SUPPORT
- Issue templates
- Pull request template
- GitHub Actions workflow

## Testing

```powershell
Set-Location C:\Workspace\mdw-toolkit
powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
mdw test
```

## License

MDW Toolkit is released under the MIT License. See `LICENSE` for details.


