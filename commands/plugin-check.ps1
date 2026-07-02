<#
MDW Plugin Check Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWPluginCheckCommand {
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

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Plugin Check"

    if (-not $pluginSlug) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug could not be resolved."
        return
    }

    $result = Invoke-MDWPluginCheck -PluginSlug $pluginSlug

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    foreach ($section in $result.Sections) {
        Write-MDWSection -Title $section.Name

        foreach ($item in $section.Items) {
            Write-MDWStatus `
                -Status $item.Status `
                -Message $item.Message
        }
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Warnings" -Value $result.WarningCount
    Write-MDWInfoCard -Label "Errors" -Value $result.ErrorCount

    if ($result.ErrorCount -gt 0) {
        Write-MDWResult `
            -Status "FAIL" `
            -Message ("Plugin Check failed with {0} errors." -f $result.ErrorCount)

        return
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWResult `
            -Status "WARN" `
            -Message ("Plugin Check passed with {0} warnings." -f $result.WarningCount)

        return
    }

    Write-MDWResult `
        -Status "OK" `
        -Message "Plugin Check passed."
}