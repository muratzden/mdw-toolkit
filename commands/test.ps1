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
            Write-MDWStatus -Status "OK" -Message $test.Name
        }
        else {
            Write-MDWStatus -Status "FAIL" -Message ("{0} - {1}" -f $test.Name, $test.Message)
        }
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWSection -Title "Warnings"

        foreach ($warning in $result.Warnings) {
            Write-MDWStatus -Status "WARN" -Message $warning
        }
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Total" -Value ($result.PassedCount + $result.FailedCount)
    Write-MDWInfoCard -Label "Passed" -Value $result.PassedCount
    Write-MDWInfoCard -Label "Failed" -Value $result.FailedCount
    Write-MDWInfoCard -Label "Warnings" -Value $result.WarningCount
    Write-MDWInfoCard -Label "Duration" -Value ("{0:N2} sec" -f $result.Duration)

    if ($result.Passed) {
        Write-MDWResult -Status "OK" -Message "Result: PASS"
    }
    else {
        Write-MDWResult -Status "FAIL" -Message "Result: FAIL"
    }

    if (-not $result.Passed) {
        throw "MDW tests failed with $($result.FailedCount) failure(s)."
    }

    Write-MDWBlank
}
