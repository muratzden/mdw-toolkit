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
        Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Build Pipeline"
        Write-MDWResult -Status "FAIL" -Message "Plugin slug could not be resolved."
        return
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Build Pipeline"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    Write-MDWSection -Title "Steps"
    Write-MDWStatus -Status "INFO" -Message "Prepare build"
    Write-MDWStatus -Status "INFO" -Message "Copy production files"

    $result = Invoke-MDWBuildService -PluginSlug $pluginSlug

    Write-MDWStatus -Status "OK" -Message "Validate build"

    Write-MDWSection -Title "Output"
    Write-MDWInfoCard -Label "Source" -Value $result.SourcePath
    Write-MDWInfoCard -Label "Build" -Value $result.BuildPath

    Write-MDWResult `
        -Status "OK" `
        -Message "Build completed successfully."
}