<#
MDW Init Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWInit {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $usage = "Usage: mdw init plugin <source-path> <plugin-slug>"

    if (-not $Arguments -or $Arguments.Count -eq 0) {
        throw "Missing init command type. $usage"
    }

    $type = $Arguments[0].ToLowerInvariant()

    if ($type -ne "plugin") {
        throw "Unsupported init command type: $($Arguments[0]). $usage"
    }

    if ($Arguments.Count -lt 2 -or [string]::IsNullOrWhiteSpace($Arguments[1])) {
        throw "Missing source path. $usage"
    }

    if ($Arguments.Count -lt 3 -or [string]::IsNullOrWhiteSpace($Arguments[2])) {
        throw "Missing plugin slug. $usage"
    }

    if ($Arguments.Count -gt 3) {
        throw "Too many arguments for init plugin. $usage"
    }

    $sourcePath = $Arguments[1]
    $pluginSlug = $Arguments[2]

    Write-Host "[MDW] Init started: $pluginSlug" -ForegroundColor Cyan

    $result = Invoke-MDWInitService -SourcePath $sourcePath -PluginSlug $pluginSlug

    Write-Host "[MDW] Source: $($result.SourcePath)"
    Write-Host "[MDW] Target: $($result.TargetPath)"

    if ($result.MainPluginFile) {
        Write-Host "[MDW] Main plugin file: $($result.MainPluginFile)"
    }

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

        throw "Init failed with $($result.ErrorCount) error(s)."
    }

    Write-Host ""
    Write-Host "[MDW] Init completed: $pluginSlug" -ForegroundColor Green
    Write-Host "[MDW] Next: mdw check $pluginSlug"
}
