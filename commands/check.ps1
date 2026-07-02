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
        Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Plugin Check"
        Write-MDWResult -Status "FAIL" -Message "Plugin slug is required."
        return
    }

    $result = Invoke-MDWCheckService -PluginSlug $pluginSlug

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Quick Plugin Check"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    Write-MDWSection -Title "Checks"

    foreach ($section in $result.Sections) {
        $hasWarning = $false
        $hasError = $false

        foreach ($item in $section.Items) {
            if ($item.Status -eq "FAIL") {
                $hasError = $true
            }

            if ($item.Status -eq "WARN") {
                $hasWarning = $true
            }
        }

        if ($hasError) {
            Write-MDWStatus -Status "FAIL" -Message $section.Name
        }
        elseif ($hasWarning) {
            Write-MDWStatus -Status "WARN" -Message $section.Name
        }
        else {
            Write-MDWStatus -Status "OK" -Message $section.Name
        }
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Warnings" -Value $result.WarningCount
    Write-MDWInfoCard -Label "Errors" -Value $result.ErrorCount

    if ($result.ErrorCount -gt 0) {
        Write-MDWResult `
            -Status "FAIL" `
            -Message ("Plugin check failed with {0} errors." -f $result.ErrorCount)

        return
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWResult `
            -Status "WARN" `
            -Message ("Plugin check completed with {0} warnings." -f $result.WarningCount)

        return
    }

    Write-MDWResult `
        -Status "OK" `
        -Message "Plugin structure valid."
}