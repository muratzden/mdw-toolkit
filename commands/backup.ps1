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

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $pluginSlug -RequireExisting

    if (-not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
        throw "Plugin directory not found: $pluginPath"
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $pluginBackupRoot = Get-MDWBackupPluginPath -PluginSlug $pluginSlug
    $backupPath = Join-Path $pluginBackupRoot $timestamp

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Backup"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    Write-MDWSection -Title "Source"
    Write-MDWInfoCard -Label "Path" -Value $pluginPath

    Write-MDWSection -Title "Steps"
    Write-MDWStatus -Status "INFO" -Message "Prepare backup directory"

    if (-not (Test-Path -LiteralPath $pluginBackupRoot)) {
        New-Item -ItemType Directory -Path $pluginBackupRoot -Force | Out-Null
    }

    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    Write-MDWStatus -Status "INFO" -Message "Copy plugin files"

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

    Write-MDWStatus -Status "OK" -Message "Backup created"

    Write-MDWSection -Title "Output"
    Write-MDWInfoCard -Label "Backup" -Value $backupPath

    Write-MDWResult -Status "OK" -Message "Backup completed."
}
