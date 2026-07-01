<#
MDW Backup Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWBackup {
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

    $pluginPath = Get-MDWPluginPath -PluginSlug $pluginSlug

    if (-not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
        throw "Plugin directory not found: $pluginPath"
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $pluginBackupRoot = Get-MDWBackupPluginPath -PluginSlug $pluginSlug
    $backupPath = Join-Path $pluginBackupRoot $timestamp

    Write-Host "[MDW] Backup started: $pluginSlug" -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $pluginBackupRoot)) {
        New-Item -ItemType Directory -Path $pluginBackupRoot -Force | Out-Null
    }

    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    Get-ChildItem -LiteralPath $pluginPath -Force | Where-Object {
        $_.Name -notin @(
            ".git",
            "node_modules",
            "vendor",
            "build",
            "dist",
            ".DS_Store"
        )
    } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $backupPath -Recurse -Force
    }

    Write-Host "[MDW] Source: $pluginPath"
    Write-Host "[MDW] Backup: $backupPath"
    Write-Host "[MDW] Backup completed: $pluginSlug" -ForegroundColor Green
}
