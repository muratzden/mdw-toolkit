<#
MDW Test Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWTest {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    Write-Host "Running MDW Tests..." -ForegroundColor Cyan
    Write-Host ""

    $result = Invoke-MDWTestService
    $currentCategory = $null

    foreach ($test in $result.Tests) {
        if ($currentCategory -ne $test.Category) {
            $currentCategory = $test.Category
            Write-Host $currentCategory -ForegroundColor Yellow
            Write-Host ""
        }

        if ($test.Passed) {
            Write-Host ("OK {0}" -f $test.Name) -ForegroundColor Green
        }
        else {
            Write-Host ("FAIL {0} - {1}" -f $test.Name, $test.Message) -ForegroundColor Red
        }
    }

    if ($result.WarningCount -gt 0) {
        Write-Host ""
        Write-Host "Warnings" -ForegroundColor Yellow

        foreach ($warning in $result.Warnings) {
            Write-Host ("- {0}" -f $warning) -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host ""
    Write-Host ("Passed : {0}" -f $result.PassedCount)
    Write-Host ""
    Write-Host ("Failed : {0}" -f $result.FailedCount)
    Write-Host ""
    Write-Host ("Warnings : {0}" -f $result.WarningCount)
    Write-Host ""
    Write-Host ("Duration : {0:N2} sec" -f $result.Duration)

    if (-not $result.Passed) {
        throw "MDW tests failed with $($result.FailedCount) failure(s)."
    }
}
