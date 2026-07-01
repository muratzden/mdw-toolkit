<#
MDW ZIP Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWZip {
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

    $toolkitRoot = Get-MDWRootPath
    $buildRoot = Join-Path $toolkitRoot "build"
    $releaseRoot = Join-Path $toolkitRoot "releases"

    $buildPath = Join-Path $buildRoot $pluginSlug
    $releasePluginRoot = Join-Path $releaseRoot $pluginSlug
    $zipPath = Join-Path $releasePluginRoot "$pluginSlug.zip"

    if (-not (Test-Path $buildPath)) {
        throw "Build directory not found. Run first: mdw build $pluginSlug"
    }

    if (-not (Test-Path $releasePluginRoot)) {
        New-Item -ItemType Directory -Path $releasePluginRoot -Force | Out-Null
    }

    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }

    Write-Host "[MDW] ZIP started: $pluginSlug" -ForegroundColor Cyan

    Compress-Archive `
        -Path $buildPath `
        -DestinationPath $zipPath `
        -Force

    Write-Host "[MDW] ZIP: $zipPath"
    Write-Host "[MDW] ZIP completed: $pluginSlug" -ForegroundColor Green
}