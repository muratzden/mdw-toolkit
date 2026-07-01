<#
MDW Release Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWRelease {
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

    Write-Host "[MDW] Release started: $pluginSlug" -ForegroundColor Cyan

    Invoke-MDWBackup -Arguments @($pluginSlug)
    Invoke-MDWClean -Arguments @($pluginSlug)
    Invoke-MDWBuild -Arguments @($pluginSlug)
    Invoke-MDWCheck -Arguments @($pluginSlug)
    Invoke-MDWZip -Arguments @($pluginSlug)

    Write-Host "[MDW] Release completed: $pluginSlug" -ForegroundColor Green
}