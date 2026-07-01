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

    Write-MDWHeader -Title "Plugin Check" -Subtitle $pluginSlug
    Write-MDWStep -Name "Checking plugin folder" -Status "INFO"

    $result = Invoke-MDWCheckService -PluginSlug $pluginSlug

    Write-MDWStatusLine -Status "OK" -Message ("Plugin folder found: {0}" -f $result.PluginPath)
    Write-MDWStatusLine -Status "OK" -Message "Validation rules completed."

    if ($result.WarningCount -gt 0) {
        Write-MDWSection -Title "Warnings"

        foreach ($warning in $result.Warnings) {
            Write-MDWStatusLine -Status "WARN" -Message $warning
        }
    }

    if ($result.ErrorCount -gt 0) {
        Write-MDWSection -Title "Errors"

        foreach ($errorItem in $result.Errors) {
            Write-MDWStatusLine -Status "FAIL" -Message $errorItem
        }

        throw "Check failed with $($result.ErrorCount) error(s)."
    }

    Write-MDWStatusLine -Status "OK" -Message "Check complete."
    Write-Host ""
}
