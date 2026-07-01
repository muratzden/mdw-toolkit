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

    Write-Host "[MDW] Doctor started" -ForegroundColor Cyan

    $result = Invoke-MDWDoctorService

    Write-Host "[MDW] Toolkit root: $($result.ToolkitRoot)"
    Write-Host ""
    Write-Host "[MDW] Environment:" -ForegroundColor Yellow

    foreach ($check in $result.Checks) {
        if ($check.Passed) {
            Write-Host ("  [OK]   {0}: {1}" -f $check.Name, $check.Message) -ForegroundColor Green
        }
        elseif ($check.Severity -eq "Error") {
            Write-Host ("  [FAIL] {0}: {1}" -f $check.Name, $check.Message) -ForegroundColor Red
        }
        else {
            Write-Host ("  [WARN] {0}: {1}" -f $check.Name, $check.Message) -ForegroundColor Yellow
        }
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

        throw "Doctor failed with $($result.ErrorCount) error(s)."
    }

    Write-Host ""
    Write-Host "[MDW] Doctor completed" -ForegroundColor Green
}
