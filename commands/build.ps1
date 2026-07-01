<#
MDW Build Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWBuild {
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

    Write-MDWHeader -Title "Build Pipeline" -Subtitle $pluginSlug
    Write-MDWStep -Name "Preparing build output" -Status "INFO"
    Write-MDWStep -Name "Copying production files" -Status "INFO"

    $result = Invoke-MDWBuildService -PluginSlug $pluginSlug

    Write-MDWStep -Name "Validating output" -Status "OK"
    Write-MDWSection -Title "Build Output"
    Write-MDWInfoCard -Label "Source" -Value $result.SourcePath
    Write-MDWInfoCard -Label "Build" -Value $result.BuildPath
    Write-MDWStatusLine -Status "OK" -Message "Build completed."
    Write-Host ""
}
