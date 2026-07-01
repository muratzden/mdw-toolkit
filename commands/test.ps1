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

    Write-MDWHeader -Title "MDW Tests" -Subtitle "Automated Test Suite"

    $result = Invoke-MDWTestService
    $currentCategory = $null

    foreach ($test in $result.Tests) {
        if ($currentCategory -ne $test.Category) {
            $currentCategory = $test.Category
            Write-MDWSection -Title $currentCategory
        }

        if ($test.Passed) {
            Write-MDWStatusLine -Status "OK" -Message $test.Name
        }
        else {
            Write-MDWStatusLine -Status "FAIL" -Message ("{0} - {1}" -f $test.Name, $test.Message)
        }
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWSection -Title "Warnings"

        foreach ($warning in $result.Warnings) {
            Write-MDWStatusLine -Status "WARN" -Message $warning
        }
    }

    Write-MDWTestSummary -Result $result

    if (-not $result.Passed) {
        throw "MDW tests failed with $($result.FailedCount) failure(s)."
    }

    Write-Host ""
}
