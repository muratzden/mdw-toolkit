<#
MDW Validate Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWValidate {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = $null

    if ($Arguments -and $Arguments.Count -gt 0) {
        $pluginSlug = $Arguments[0]
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Validate"

    $result = Invoke-MDWValidateService -ToolkitRoot (Get-MDWToolkitPath) -PluginSlug $pluginSlug

    Write-MDWSection -Title "Scope"
    Write-MDWInfoCard -Label "Plugin" -Value $result.PluginSlug
    Write-MDWInfoCard -Label "Path" -Value $result.PluginPath

    foreach ($section in $result.Sections) {
        Write-MDWSection -Title $section.Name

        foreach ($item in $section.Items) {
            Write-MDWStatus -Status $item.Status -Message $item.Message
        }
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Warnings" -Value $result.WarningCount
    Write-MDWInfoCard -Label "Errors" -Value $result.ErrorCount

    if ($result.ErrorCount -gt 0) {
        Write-MDWResult -Status "FAIL" -Message ("Validate failed with {0} errors." -f $result.ErrorCount)
        return
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWResult -Status "WARN" -Message ("Validate passed with {0} warnings." -f $result.WarningCount)
        return
    }

    Write-MDWResult -Status "OK" -Message "Validate passed."
}
