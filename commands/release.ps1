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

    Write-MDWHeader -Title "Release Pipeline" -Subtitle $pluginSlug
    Write-MDWPipeline -Steps @("Backup", "Clean", "Build", "Check", "ZIP", "Release Complete")

    Write-MDWSection -Title "Running"
    Write-MDWStep -Name "Backup" -Status "INFO"
    Invoke-MDWBackup -Arguments @($pluginSlug)

    Write-MDWStep -Name "Clean" -Status "INFO"
    Invoke-MDWClean -Arguments @($pluginSlug)

    Write-MDWStep -Name "Build" -Status "INFO"
    Invoke-MDWBuild -Arguments @($pluginSlug)

    Write-MDWStep -Name "Check" -Status "INFO"
    Invoke-MDWCheck -Arguments @($pluginSlug)

    Write-MDWStep -Name "ZIP" -Status "INFO"
    Invoke-MDWZip -Arguments @($pluginSlug)

    Write-MDWStatusLine -Status "OK" -Message "Release complete."
    Write-Host ""
}
