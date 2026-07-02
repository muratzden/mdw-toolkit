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

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Init Plugin"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    Write-MDWSection -Title "Steps"
    Write-MDWStatus -Status "INFO" -Message "Import plugin files"

    $result = Invoke-MDWInitService -SourcePath $sourcePath -PluginSlug $pluginSlug

    Write-MDWStatus -Status "OK" -Message "Plugin files imported"

    Write-MDWSection -Title "Paths"
    Write-MDWInfoCard -Label "Source" -Value $result.SourcePath
    Write-MDWInfoCard -Label "Target" -Value $result.TargetPath

    if ($result.MainPluginFile) {
        Write-MDWInfoCard -Label "Main File" -Value $result.MainPluginFile
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWSection -Title "Warnings"

        foreach ($warning in $result.Warnings) {
            Write-MDWStatus -Status "WARN" -Message $warning
        }
    }

    if ($result.ErrorCount -gt 0) {
        Write-MDWSection -Title "Errors"

        foreach ($errorItem in $result.Errors) {
            Write-MDWStatus -Status "FAIL" -Message $errorItem
        }

        Write-MDWResult -Status "FAIL" -Message ("Init failed with {0} error(s)." -f $result.ErrorCount)
        throw "Init failed with $($result.ErrorCount) error(s)."
    }

    Write-MDWSection -Title "Next"
    Write-MDWInfoCard -Label "Command" -Value ("mdw check {0}" -f $pluginSlug)

    Write-MDWResult -Status "OK" -Message "Init completed."
}
