<#
MDW New Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWNew {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $usage = "Usage: mdw new plugin <plugin-slug>"

    if (-not $Arguments -or $Arguments.Count -eq 0) {
        throw "Missing new command type. $usage"
    }

    $type = $Arguments[0].ToLowerInvariant()

    if ($type -ne "plugin") {
        throw "Unsupported new command type: $($Arguments[0]). $usage"
    }

    if ($Arguments.Count -lt 2 -or [string]::IsNullOrWhiteSpace($Arguments[1])) {
        throw "Missing plugin slug. $usage"
    }

    if ($Arguments.Count -gt 2) {
        throw "Too many arguments for new plugin. $usage"
    }

    $pluginSlug = $Arguments[1].Trim()

    if ($pluginSlug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        throw "Invalid plugin slug: $pluginSlug. Use lowercase letters, numbers, and single hyphens only."
    }

    $pluginsRoot = Get-MDWPluginsPath
    $projectPath = Get-MDWPluginPath -PluginSlug $pluginSlug

    if (Test-Path -LiteralPath $projectPath) {
        throw "Plugin directory already exists: $projectPath"
    }

    $pluginName = ($pluginSlug -split '-' | ForEach-Object {
        if ($_.Length -eq 1) {
            $_.ToUpperInvariant()
        }
        else {
            $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
        }
    }) -join ' '

    $constantPrefix = ($pluginSlug -replace '[^A-Za-z0-9]', '_').ToUpperInvariant()

    if ($constantPrefix -match '^[0-9]') {
        $constantPrefix = "MDW_$constantPrefix"
    }

    $createdProjectRoot = $false

    try {
        if (-not (Test-Path -LiteralPath $pluginsRoot)) {
            New-Item -ItemType Directory -Path $pluginsRoot -Force | Out-Null
        }

        New-Item -ItemType Directory -Path $projectPath -ErrorAction Stop | Out-Null
        $createdProjectRoot = $true

        foreach ($directoryName in @("languages", "assets", "includes")) {
            New-Item -ItemType Directory -Path (Join-Path $projectPath $directoryName) -Force -ErrorAction Stop | Out-Null
        }

        $pluginFilePath = Join-Path $projectPath "$pluginSlug.php"
        $readmeTxtPath = Join-Path $projectPath "readme.txt"
        $readmeMdPath = Join-Path $projectPath "README.md"
        $gitignorePath = Join-Path $projectPath ".gitignore"

        $pluginFileContent = @"
<?php
/**
 * Plugin Name: $pluginName
 * Plugin URI: https://example.com/plugins/$pluginSlug
 * Description: A WordPress plugin scaffolded with MDW Toolkit.
 * Version: 0.1.0
 * Author: MDW Toolkit
 * Author URI: https://example.com
 * Text Domain: $pluginSlug
 * Domain Path: /languages
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * License: GPL-2.0-or-later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 *
 * @package $constantPrefix
 */

if (!defined('ABSPATH')) {
    exit;
}

define('${constantPrefix}_VERSION', '0.1.0');
define('${constantPrefix}_FILE', __FILE__);
define('${constantPrefix}_PATH', plugin_dir_path(__FILE__));
define('${constantPrefix}_URL', plugin_dir_url(__FILE__));
"@

        $readmeTxtContent = @"
=== $pluginName ===
Contributors: mdw-toolkit
Tags: wordpress, plugin
Requires at least: 6.0
Tested up to: 6.5
Stable tag: 0.1.0
Requires PHP: 7.4
License: GPL-2.0-or-later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

A WordPress plugin scaffolded with MDW Toolkit.

== Description ==

A WordPress plugin scaffolded with MDW Toolkit.

== Installation ==

1. Upload the plugin files to the `/wp-content/plugins/$pluginSlug` directory, or install the plugin through the WordPress plugins screen.
2. Activate the plugin through the Plugins screen in WordPress.

== Changelog ==

= 0.1.0 =
* Initial scaffold.
"@

        $readmeMdContent = @"
# $pluginName

A WordPress plugin scaffolded with MDW Toolkit.

## Requirements

- WordPress 6.0 or newer
- PHP 7.4 or newer

## Development

This plugin was created with MDW Toolkit.
"@

        $gitignoreContent = @"
.DS_Store
Thumbs.db
node_modules/
vendor/
build/
dist/
*.log
*.tmp
"@

        Set-Content -Path $pluginFilePath -Value $pluginFileContent -Encoding UTF8 -ErrorAction Stop
        Set-Content -Path $readmeTxtPath -Value $readmeTxtContent -Encoding UTF8 -ErrorAction Stop
        Set-Content -Path $readmeMdPath -Value $readmeMdContent -Encoding UTF8 -ErrorAction Stop
        Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8 -ErrorAction Stop

        foreach ($keepFile in @(
            "languages\.gitkeep",
            "assets\.gitkeep",
            "includes\.gitkeep"
        )) {
            Set-Content -Path (Join-Path $projectPath $keepFile) -Value "" -Encoding UTF8 -ErrorAction Stop
        }

        if (Get-Command git -ErrorAction SilentlyContinue) {
            Push-Location $projectPath

            try {
                & git init | Out-Null

                if ($LASTEXITCODE -ne 0) {
                    Write-Host "[MDW] Warning: git init failed. Plugin files were created successfully." -ForegroundColor Yellow
                }
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "[MDW] Warning: git was not found. Skipping git init." -ForegroundColor Yellow
        }

        Write-Host "[MDW] Plugin created: $projectPath" -ForegroundColor Green
    }
    catch {
        if ($createdProjectRoot -and (Test-Path -LiteralPath $projectPath)) {
            Remove-Item -LiteralPath $projectPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        throw
    }
}
