<#
MDW Clean Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWClean {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = $null

    if ($Arguments -and $Arguments.Count -gt 0) {
        $pluginSlug = $Arguments[0]
    }

    if (-not $pluginSlug) {
        $currentPath = Get-Location
        $pluginSlug = Split-Path $currentPath -Leaf
    }

    if (-not $pluginSlug) {
        throw "Plugin slug could not be resolved."
    }

    Write-Host "[MDW] Clean started: $pluginSlug" -ForegroundColor Cyan

    $toolkitRoot = Get-MDWRootPath
    $workspaceRoot = Split-Path $toolkitRoot -Parent
    $pluginsRoot = Join-Path $workspaceRoot "Plugins"

    $pluginPath = Join-Path $pluginsRoot $pluginSlug
    $buildPath = Join-Path (Join-Path $workspaceRoot "Build") $pluginSlug
    $releasePath = Join-Path (Join-Path $workspaceRoot "Releases") $pluginSlug
    $legacyBuildPath = Join-Path (Join-Path $toolkitRoot "build") $pluginSlug
    $legacyReleasePath = Join-Path (Join-Path $toolkitRoot "releases") $pluginSlug

    if (-not (Test-Path $pluginPath)) {
        throw "Plugin directory not found: $pluginPath"
    }

    $pathsToClean = @(
        $buildPath,
        $releasePath,
        $legacyBuildPath,
        $legacyReleasePath
    )

    foreach ($path in $pathsToClean) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force
            Write-Host "[MDW] Removed: $path"
        }
    }

    $temporaryPatterns = @(
        "*.tmp",
        "*.log",
        "*.bak",
        "*.zip"
    )

    foreach ($pattern in $temporaryPatterns) {
        Get-ChildItem -Path $pluginPath -Filter $pattern -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -Path $_.FullName -Force
                Write-Host "[MDW] Removed temp file: $($_.FullName)"
            }
    }

    Write-Host "[MDW] Clean completed: $pluginSlug" -ForegroundColor Green
}
