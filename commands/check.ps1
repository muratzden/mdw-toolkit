<#
MDW Check Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWCheck {
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

    Write-Host "[MDW] Check started: $pluginSlug" -ForegroundColor Cyan

    $result = Invoke-MDWCheckService -PluginSlug $pluginSlug

    Write-Host "[MDW] Plugin path: $($result.PluginPath)"

    if ($result.WarningCount -gt 0) {
        Write-Host ""
        Write-Host "[MDW] Warnings:" -ForegroundColor Yellow

        foreach ($warning in $result.Warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }

    if ($result.ErrorCount -gt 0) {
        Write-Host ""
        Write-Host "[MDW] Errors:" -ForegroundColor Red

        foreach ($errorItem in $result.Errors) {
            Write-Host "  - $errorItem" -ForegroundColor Red
        }

        throw "Check failed with $($result.ErrorCount) error(s)."
    }

    Write-Host ""
    Write-Host "[MDW] Check completed: $pluginSlug" -ForegroundColor Green
}
