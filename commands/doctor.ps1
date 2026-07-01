<#
MDW Doctor Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWDoctor {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    Write-MDWHeader -Title "MDW Doctor" -Subtitle "Development Environment"

    $result = Invoke-MDWDoctorService

    Write-MDWInfoCard -Label "Toolkit" -Value $result.ToolkitRoot
    Write-MDWSection -Title "Environment"

    foreach ($check in $result.Checks) {
        if ($check.Passed) {
            Write-MDWStatusLine -Status "OK" -Message ("{0}: {1}" -f $check.Name, $check.Message)
        }
        elseif ($check.Severity -eq "Error") {
            Write-MDWStatusLine -Status "FAIL" -Message ("{0}: {1}" -f $check.Name, $check.Message)
        }
        else {
            Write-MDWStatusLine -Status "WARN" -Message ("{0}: {1}" -f $check.Name, $check.Message)
        }
    }

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

        throw "Doctor failed with $($result.ErrorCount) error(s)."
    }

    Write-MDWStatusLine -Status "OK" -Message "Doctor completed."
    Write-Host ""
}
